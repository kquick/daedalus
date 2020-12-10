#include "runner.h"
#include "value.h"
#include "action.h"
#include "cfg.h"

#include "util.h"
#include "debug.h"

//-----------------------------------------------------------------------//
// Runtime Library: Naive Backtracking Runner
//-----------------------------------------------------------------------//


typedef enum {
  CFalse,
  CTrue,
  CEarly,
} CommitFlag;

typedef struct _CommitStack {
    CommitFlag head;
    struct _CommitStack * next;
} CommitStack;

CommitStack * emptyCommitStack = NULL;

CommitStack * addCommitStack(CommitStack * hst) {
    CommitStack * st = ALLOCMEM(sizeof(CommitStack));
    st->head = CFalse;
    st->next = hst;
    return st;
}

CommitStack * popCommitStack(CommitStack* hst) {
    if (hst == NULL) {
        LOGE("Attempting to pop from an empty commit stack");
        return hst;
    }

    //TODO: It seems possible that we can delete the removed node here
    //(Because I don't think the commit stack nodes are shared)
    //But need to recheck this
    return hst->next;
}

int hasCommitted(CommitStack* hst) {
    if (hst == NULL)
        return 0;
    return hst->head == CTrue || hst->head == CEarly;
}

CommitStack* updateCommitStack(CommitStack* hst) {
    if (hst == NULL) {
        return hst;
    }

    //TODO: Would an in-place update work? If these nodes can be shared
    //that wont work. The current approach duplicates all nodes in the chain
    //of recursion and can be rather expensive!
    //TODO: We could do this in a while-loop more efficiently; but sticking to
    //recursion for now to maintain alignment to Haskell
    CommitStack* newHst = ALLOCMEM(sizeof(CommitStack));
    if (hst->head == CFalse) {
        newHst->head = CEarly;
        newHst->next = hst->next;
    }
    else {
        CommitStack* updatedStack = updateCommitStack(hst->next);
        newHst->head = hst->head;
        newHst->next = updatedStack;
    }
    return newHst;
}

typedef int DepthComputation;

typedef DepthComputation BacktrackStackInfo;


//NOTE: We are currently representing the emptu BacktrackStack (`BEmpty`)
//as a NULL pointer. We _could_ go with an exact mapping from Haskell if needed
//using a union. But it is unclear that is needed at this point.
typedef struct _BacktrackStack {
    BacktrackStackInfo backtrackStackInfo;
    struct _BacktrackStack* next;
    Cfg* cfg;
    Choice* choice;
} BacktrackStack;

BacktrackStack* addLevel(
    BacktrackStackInfo backtrackStackInfo, BacktrackStack* hst,
    Cfg* cfg, Choice* choice
)
{
    BacktrackStack* newNode = ALLOCMEM(sizeof(BacktrackStack));
    newNode->backtrackStackInfo = backtrackStackInfo;
    newNode->next = hst;
    newNode->cfg = cfg;
    newNode->choice = choice;

    return newNode;
}

typedef struct {
    Cfg* cfg;
    Action* action;
    int state;
} ResumptionTip;

typedef struct _Resumption {
    CommitStack* commitStack;
    BacktrackStack* backtrackStack;
    DepthComputation depthComputation;
    ResumptionTip* resumptionTip;
} Resumption ;

Resumption* emptyResumption = NULL;

Resumption* addResumption(Resumption* resumption, Cfg* cfg, Choice* choice) {
    //First create a new Resumption instance and copy the current data to it
    //The following bits will then only modify the parts that they need to
    Resumption* newResumption = ALLOCMEM(sizeof(Resumption));
    memcpy(newResumption, resumption, sizeof(Resumption));

    //The new ResumptionTip is based on the current configuration and the Action/State
    //pair derived from the topmost choice. We pre-compute that here for convenience
    ResumptionTip* newResumptionTip = NULL;
    if (choice->len > 0) {
        newResumptionTip = ALLOCMEM(sizeof(ResumptionTip));
        newResumptionTip->cfg = cfg;
        newResumptionTip->action = choice->transitions->pAction;
        newResumptionTip->state = choice->transitions->state;
    }

    switch (choice->tag) {
        case UNICHOICE: {
            newResumption->resumptionTip = newResumptionTip;
            newResumption->depthComputation += 1;
            break;
        }
        case SEQCHOICE: {
            CommitStack* newCommitStack = addCommitStack(resumption->commitStack);
            BacktrackStack* newBacktrackStack = addLevel(
                resumption->depthComputation, resumption->backtrackStack, cfg, choice
            );

            newResumption->commitStack = newCommitStack;
            newResumption->backtrackStack = newBacktrackStack;
            newResumption->depthComputation += 1;
            newResumption->resumptionTip = newResumptionTip;
            break;
        }
        case PARCHOICE: {
            BacktrackStack* newBacktrackStack = addLevel(
                resumption->depthComputation, resumption->backtrackStack, cfg, choice
            );

            newResumption->backtrackStack = newBacktrackStack;
            newResumption->depthComputation += 1;
            newResumption->resumptionTip = newResumptionTip;
            break;
        }
    }
}

ResumptionTip* getActionCfgAtLevel(Resumption* resumption) {
    return resumption->resumptionTip;
}

Resumption* earlyUpdateCommitResumption(Resumption* resumption) {
    Resumption* newResumption = ALLOCMEM(sizeof(Resumption));
    memcpy(newResumption, resumption, sizeof(Resumption));

    CommitStack* newCommitStack = earlyUpdateCommitResumption(resumption->commitStack);
    newResumption->commitStack = newCommitStack;
    return newResumption;
}

Resumption* cutResumption(Resumption* resumption) {
    Resumption* newResumption = ALLOCMEM(sizeof(Resumption));
    memcpy(newResumption, resumption, sizeof(Resumption));

    newResumption->commitStack = emptyCommitStack;
    newResumption->backtrackStack = NULL; //TODO: Maybe introduce emptyBacktrackStack (eq of BEmpty)?
    return newResumption;
}

Resumption* _getNext(CommitStack* commitStack, BacktrackStack* backtrackStack) {
    if (backtrackStack == NULL) {
        return NULL;
    }

    if (backtrackStack->choice->len == 0) {
        LOGE("Broken invariant, the current choice cannot be empty");
        return NULL;
    }

    switch (backtrackStack->choice->tag) {
        case UNICHOICE: {
            LOGE("Broken invariant, the level cannot be UniChoice");
            return NULL;
        }
        case SEQCHOICE: {
            if (backtrackStack->choice->len == 1 || hasCommitted(commitStack)) {
                CommitStack* newCommitStack = popCommitStack(commitStack);
                return _getNext(newCommitStack, backtrackStack->next);
            } else {
                CommitStack* newCommitStack = popCommitStack(commitStack);

                Resumption resumption = {
                    .commitStack = newCommitStack,
                    .backtrackStack = backtrackStack->next,
                    .depthComputation = backtrackStack->backtrackStackInfo,
                    .resumptionTip = NULL
                };

                Choice* newChoice = ALLOCMEM(sizeof(Choice));
                newChoice->len = backtrackStack->choice->len - 1;
                newChoice->tag = SEQCHOICE;
                newChoice->transitions = &backtrackStack->choice->transitions[1];

                return addResumption(&resumption, backtrackStack->cfg, newChoice);
            }
        }
        case PARCHOICE: {
            if (backtrackStack->choice->len == 1) {
                return _getNext(commitStack, backtrackStack->next);
            } else {
                Resumption resumption = {
                    .commitStack = commitStack,
                    .backtrackStack = backtrackStack->next,
                    .depthComputation = backtrackStack->backtrackStackInfo,
                    .resumptionTip = NULL
                };

                Choice* newChoice = ALLOCMEM(sizeof(Choice));
                newChoice->len = backtrackStack->choice->len - 1;
                newChoice->tag = PARCHOICE;
                newChoice->transitions = &backtrackStack->choice->transitions[1];

                return addResumption(&resumption, backtrackStack->cfg, newChoice);
            }
        }
    }
}

Resumption* nextResumption(Resumption* resumption) {
    return _getNext(resumption->commitStack, resumption->backtrackStack);
}

// WE ARE HEREER!!!!!!!

typedef struct _Stack {
    int state;
    int pos;
    Cfg * cfg;
    struct _Stack* up;
} Stack;

Stack * initStack(Cfg * cfg) {
    return NULL;
}

Stack * pushStack(int state, int pos, Cfg * cfg, Stack *stack) {
    Stack * st = malloc(sizeof(Stack));
    st->state = state;
    st->pos = pos;
    st->cfg = cfg;
    st->up = stack;

    return st;
}

typedef struct _Result {
    Value * value;
    struct _Result * next;
} Result;

Result * initResult() {
    return NULL;
}

Result * addResult(Value * v, Result * res){
    Result * r = malloc(sizeof(Result));
    r->value = v;
    r->next = res;

    return r;
}

void print_Result(Result * r){

   printf("Results:\n");
    int i = 0;
    while (r != NULL) {
        i++;
        printf("#%d ", i);
        print_Value(r->value);
        r = r->next;
        if (r != NULL)
            printf("\n");
    }
    return;
}

Result * runner(Aut aut, Cfg * cfg , Stack * st, Result * r);
Result * backtrack(Aut aut, Stack * st, Result * r);
Result * step(Aut aut, Action * act, int arrivState, Stack * st, Result * r);

Result * runner(Aut aut, Cfg * cfg , Stack * st, Result * r) {
    LOGD("STATE: %d", cfg->state);
    //printf("Stack at: %p\n", cfg->ctrl);

    Result * new_res = r;

    if (isEmptyStackCtrl(cfg->ctrl) && cfg->state == aut.accepting) {
        new_res = addResult(cfg->sem->value, r);
        LOGI("Solution found!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    }

    Choice ch = aut.table[cfg->state];
    ActionStatePair* tr = ch.transitions;

    Stack * newStack;
    LOGD("Tag: %d", ch.tag);
    switch (ch.tag) {
        case UNICHOICE: {
            Action* act = tr[0].pAction;
            int arrivalState = tr[0].state;

            newStack = pushStack(cfg->state, 1, cfg, st);
            return step(aut, act, arrivalState, newStack, new_res);
            break;
        };
        case PARCHOICE: {
            Action * act = tr[0].pAction;
            int arrivalState = tr[0].state;

            newStack = pushStack(cfg->state, 1, cfg, st);
            return step(aut, act, arrivalState, newStack, new_res);
            break;
        };
        case SEQCHOICE: {
            //TODO:
        }
        case EMPTYCHOICE: {
            LOGD("EMPTYCHOICE");
            //Action pop = MAKE_ACT_POP();
            int arrivalState = -42;
            Action act = { .tag = ACT_ControlAction, .controlAction = { .tag = ACT_Pop} };

            //newStack = pushStack(cfg->state, 1, cfg, st);
            newStack = pushStack(arrivalState, 1, cfg, st);
            return step(aut, &act, arrivalState, newStack, new_res);
            break;
        }
        default: {
            printf("Exited\n");
            exit(1);
        };
    }
}

Result * step(Aut aut, Action *act, int arrivState, Stack *st, Result * r) {
    LOGD("STEP: action:%s arrivState:%d", actionToString(act), arrivState);

    Cfg* cfg = st->cfg;
    Cfg* newCfg = NULL;
    newCfg = applyAction(act, cfg, arrivState);

    if (newCfg == NULL) {
        return backtrack(aut, st, r);
    } else {
        return runner(aut, newCfg, st, r);
    }
}

Result * backtrack(Aut aut, Stack *st, Result * res){
    LOGD("BACKTRACK");
    if (st == NULL) {
        return res;
    } else {
        int state = st->state;
        int pos = st->pos;
        Stack* upStack = st->up;

        if (pos >= aut.table[state].len) {
            return backtrack(aut, upStack, res);
        } else {
            Stack * newStack = pushStack(state, pos+1, st->cfg, upStack);
            return step(
                aut,
                aut.table[state].transitions[pos].pAction,
                aut.table[state].transitions[pos].state,
                newStack,
                res
            );
        }
    }
}

void runAut(Aut aut, FILE* input) {
    Result * res = runner(
        aut,
        mkCfg(aut.initial, initInput(input), initStackCtrl(), initStackSem()),
        initStack(NULL),
        initResult()
    );

    print_Result(res);
    printf("\n");
}
