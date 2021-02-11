{-# Language TupleSections, GeneralizedNewtypeDeriving #-}
{-# Language BlockArguments #-}
module Daedalus.Core.Inline (inlineModule) where

import Data.Map (Map)
import qualified Data.Map as Map
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Data.Foldable as Foldable
import MonadLib
import Data.List(partition)
import Data.Graph.SCC(stronglyConnComp)
import Data.Graph(SCC(..))

import Daedalus.Panic(panic)
import Daedalus.PP(pp)
import Daedalus.Rec(Rec(..))

import Daedalus.Core.Free(FreeVars(freeFVars))
import Daedalus.Core.Subst

import Daedalus.Core.Decl
import Daedalus.Core.Expr
import Daedalus.Core.Grammar
import Daedalus.Core.Basics

inlineModule :: [FName] -> Module -> Module
inlineModule no = runInlineM (Set.fromList no) . expandModule


data Inlineable = Inlineable
  { inlineE  :: Map FName (Fun Expr)
  , inlineG  :: Map FName (Fun Grammar)
  , noInline :: Set FName
  }

addE :: Fun Expr -> Inlineable -> Inlineable
addE f i = i { inlineE = Map.insert (fName f) f (inlineE i) }

addG :: Fun Grammar -> Inlineable -> Inlineable
addG f i = i { inlineG = Map.insert (fName f) f (inlineG i) }

newtype InlineM a = InlineM (StateT Inlineable Id a)
  deriving (Functor,Applicative,Monad)

runInlineM :: Set FName -> InlineM a -> a
runInlineM no (InlineM m) = fst $ runId $ runStateT s m
  where s = Inlineable { inlineE = Map.empty, inlineG = Map.empty
                       , noInline = no }

shouldExpand :: (Inlineable -> Map FName a) -> FName -> InlineM (Maybe a)
shouldExpand f this = InlineM (Map.lookup this . f <$> get)

isInlineable :: FName -> InlineM Bool
isInlineable f = InlineM (not . (f `Set.member`) . noInline <$> get)

instantiate :: Subst e => Fun e -> [Expr] -> e
instantiate f es =
  case fDef f of
    External -> panic "instantiate"
                  [ "Trying to inline a primitve: " ++ show (pp (fName f)) ]
    Def e ->
      let su = Map.fromList (fParams f `zip` es)
      in (substitute su e)

updateInlineable :: (Inlineable -> Inlineable) -> InlineM ()
updateInlineable f = InlineM (sets_ f)


-- | Do inlining in the given thing
class Expand e where
  expand :: e -> InlineM e

instance Expand Expr where
  expand expr =
    case expr of
      Var {} -> pure expr
      PureLet x e1 e2 -> PureLet x <$> expand e1 <*> expand e2
      Struct t fs -> Struct t <$> forM fs \(f,e) -> (f,) <$> expand e
      ECase c -> ECase <$> expand c

      Ap0 {} -> pure expr
      Ap1 op e -> Ap1 op <$> expand e
      Ap2 op e1 e2 -> Ap2 op <$> expand e1 <*> expand e2
      Ap3 op e1 e2 e3 -> Ap3 op <$> expand e1 <*> expand e2 <*> expand e3
      ApN op es ->
        do es' <- traverse expand es
           case op of
             CallF f ->
               do mb <- shouldExpand inlineE f
                  pure case mb of
                          Nothing  -> ApN op es'
                          Just def -> instantiate def es'
             _ -> pure (ApN op es')

instance Expand e => Expand (Case e) where
  expand (Case e rs) = Case <$> expand e <*> forM rs \(p,r) -> (p,) <$> expand r

instance Expand Grammar where
  expand gram =
    case gram of
      Pure e -> Pure <$> expand e
      GetStream -> pure gram
      SetStream e -> SetStream <$> expand e
      Fail e t mb -> Fail e t <$> traverse expand mb
      Do_ g1 g2 -> Do_ <$> expand g1 <*> expand g2
      Do  x g1 g2 -> Do x <$> expand g1 <*> expand g2
      Let x e g -> Let x <$> expand e <*> expand g
      OrBiased g1 g2 -> OrBiased <$> expand g1 <*> expand g2
      OrUnbiased g1 g2 -> OrUnbiased <$> expand g1 <*> expand g2
      Call f es ->
        do es' <- traverse expand es
           mb <- shouldExpand inlineG f
           pure case mb of
                   Nothing  -> Call f es'
                   Just yes -> instantiate yes es'
      Annot a g -> Annot a <$> expand g
      GCase c   -> GCase <$> expand c

instance Expand e => Expand (Fun e) where
  expand f =
    case fDef f of
      Def e ->
        do e' <- expand e
           pure f { fDef = Def e' }
      External -> pure f

--------------------------------------------------------------------------------

-- Inline all: very aggressive
-- XXX: we probably want more configuration here, e.g
--    * hints for what to inline and what not to
--    * whihc definitions we may want to keep, even if they are
--      to be inlined (in case we want to make them into entry points)

orderFuns :: (FreeVars e) => [Fun e] -> [Rec (Fun e)]
orderFuns ins = comps ins
  where
  callMap   = Map.fromListWith Set.union
                [ (v,Set.singleton n)
                | (n,vs) <- map deps ins, v <- Set.toList vs
                ]
  callersOf f = Map.findWithDefault Set.empty f callMap

  deps f = (fName f, freeFVars (fDef f))
  comps  = concatMap cvt . stronglyConnComp . map node
  cvt sc = case sc of
             AcyclicSCC n -> [NonRec n]
             CyclicSCC ns -> breakLoop ns
{-
               let loc = Set.fromList (map fName ns)
                   hasExt f = not
                            $ Set.null
                            $ Map.findWithDefault Set.empty f callMap
                                                        `Set.difference` loc
                in MutRec [ (hasExt (fName n),n) | (n <- ns ]
-}

  node a = case deps a of
             (x,xs) -> (a,x,Set.toList xs)

  breakLoop els
    | null els = []
    | otherwise =
    let loc         = Set.fromList (map fName els)
        hasExt fu   = not (callersOf (fName fu) `Set.isSubsetOf` loc)
        (rec,rest)  = partition hasExt els
    in if null rec then [MutRec rest]
                   else orderFuns rest ++ [MutRec rec]



inlineAll ::
  (Expand e, FreeVars e) =>
  (Fun e -> Inlineable -> Inlineable) ->
  [Fun e] -> InlineM [Fun e]
inlineAll ext = fmap concat . traverse (inlineRec ext) . orderFuns

inlineRec ::
  (Expand e) =>
  (Fun e -> Inlineable -> Inlineable) ->
  Rec (Fun e) -> InlineM [Fun e]
inlineRec ext rec =
  do r1 <- traverse expand rec
     case r1 of
       NonRec f | Def {} <- fDef f ->
          do yes <- isInlineable (fName f)
             if yes then updateInlineable (ext f) >> pure []
                    else pure (Foldable.toList r1)

       _ -> pure (Foldable.toList r1)


expandModule :: Module -> InlineM Module
expandModule m =
  do efuns <- inlineAll addE (mFFuns m)
     gfuns <- inlineAll addG (mGFuns m)
     pure m { mFFuns = efuns, mGFuns = gfuns }


-- X -> [*A -> B, B -> A]

