#ifndef DDL_INTEGER_H
#define DDL_INTEGER_H

// #define QUICK_INTEGER 1



#ifdef QUICK_INTEGER
#include <ddl/int.h>
#else

#include <gmpxx.h>
#include <ddl/debug.h>
#include <ddl/boxed.h>
#include <ddl/size.h>

namespace DDL {

class Integer;

static bool operator <= (Integer x, Integer y);
static bool operator >= (Integer x, Integer y);

class Integer : public Boxed<mpz_class> {

  template <typename rep>
  rep toUnsigned() {
    mpz_t r;
    mpz_init(r);
    mpz_fdiv_r_2exp(r, getValue().get_mpz_t(),8*sizeof(rep));

    rep result = 0;
    mpz_export(&result, NULL, 1, sizeof(rep), 0, 0, r);
    return result;
  }

  template <typename sign, typename usign>
  sign toSigned() {
    static_assert(sizeof(sign) == sizeof(usign));

    usign u = 0;
    mpz_t r;
    mpz_init(r);
    mpz_fdiv_r_2exp(r,getValue().get_mpz_t(),8*sizeof(sign));
    mpz_export(&u, NULL, 1, sizeof(sign), 0, 0, r);

    sign result = static_cast<usign>(u);
    return result;
  }



public:
  Integer()                 : Boxed<mpz_class>()               {}
  Integer(const char* str)  : Boxed<mpz_class>(mpz_class(str)) {}

  // unsigned constructors
  Integer(uint8_t x)  : Boxed<mpz_class>(static_cast<unsigned long>(x)) {}
  Integer(uint16_t x) : Boxed<mpz_class>(static_cast<unsigned long>(x)) {}
  Integer(uint32_t x) : Boxed<mpz_class>(static_cast<unsigned long>(x)) {}
  Integer(uint64_t x) : Boxed<mpz_class>(static_cast<unsigned long>(x)) {
    if constexpr (sizeof(uint64_t) > sizeof(unsigned long))
      if (x > std::numeric_limits<unsigned long>::max()) {
        mpz_import(getValue().get_mpz_t(), 1, 1, 8, 0, 0, &x);
      }
  }

  // signed constructors
  Integer(int8_t x)  : Boxed<mpz_class>(static_cast<long>(x)) {}
  Integer(int16_t x) : Boxed<mpz_class>(static_cast<long>(x)) {}
  Integer(int32_t x) : Boxed<mpz_class>(static_cast<long>(x)) {}
  Integer(int64_t x) : Boxed<mpz_class>(static_cast<long>(x)) {
    if constexpr (sizeof(int64_t) > sizeof(long)) {
      if (x > std::numeric_limits<long>::max()) {
        mpz_import(getValue().get_mpz_t(), 1, 1, 8, 0, 0, &x);
      } else
      if (x < std::numeric_limits<long>::min()) {
        mpz_class& c = getValue();
        uint64_t v = std::numeric_limits<uint64_t>::max() -
                     static_cast<uint64_t>(x);
        mpz_import(c.get_mpz_t(), 1, 1, 8, 0, 0, &v);
        c = -c - 1;
      }
    }
  }


  Integer(Boxed<mpz_class> x) : Boxed<mpz_class>(x)              {}
  Integer(mpz_class &&x)      : Boxed<mpz_class>(std::move(x))   {}

  bool isNatural() { return sgn(getValue()) >= 0; }

  void exportI(uint8_t &x)  { x = toUnsigned<uint8_t>(); }
  void exportI(uint16_t &x) { x = toUnsigned<uint16_t>(); }
  void exportI(uint32_t &x) { x = toUnsigned<uint32_t>(); }
  void exportI(uint64_t &x) { x = toUnsigned<uint64_t>(); }

  void exportI(int8_t &x)  { x = toSigned<int8_t,uint8_t>(); }
  void exportI(int16_t &x) { x = toSigned<int16_t,uint16_t>(); }
  void exportI(int32_t &x) { x = toSigned<int32_t,uint32_t>(); }
  void exportI(int64_t &x) { x = toSigned<int64_t,uint64_t>(); }





  // assumes we know things will fit
  unsigned long asULong()    { return getValue().get_ui(); }
  long          asSLong()    { return getValue().get_si(); }

  bool          fitsULong()  { return getValue().fits_ulong_p(); }
  bool          fitsSLong()  { return getValue().fits_slong_p(); }

  // Mutable shift in place.
  // To be only used when we are the unique owners of this
  void mutShiftL(size_t amt) {
    mpz_class &r = getValue();
    r <<= amt;
  }

  // Mutable shift in place.
  // To be only used when we are the unique owners of this
  void mutShiftR(size_t amt) {
    mpz_class &r = getValue();
    r >>= amt;
  }

};

static inline
int compare(Integer x, Integer y) { return cmp(x.getValue(),y.getValue()); }

// borrow
static inline
bool operator == (Integer x, Integer y) { return x.getValue() == y.getValue(); }

// borrow
static inline
bool operator != (Integer x, Integer y) { return x.getValue() != y.getValue(); }

// borrow
static inline
bool operator <  (Integer x, Integer y) { return x.getValue() <  y.getValue(); }

// borrow
static inline
bool operator <= (Integer x, Integer y) { return x.getValue() <= y.getValue(); }

// borrow
static inline
bool operator >  (Integer x, Integer y) { return x.getValue() >  y.getValue(); }

// borrow
static inline
bool operator >= (Integer x, Integer y) { return x.getValue() >= y.getValue(); }



// borrow
static inline
std::ostream& operator<<(std::ostream& os, Integer x) {
  return os << x.getValue();
}

// borrow
static inline
std::ostream& toJS(std::ostream& os, Integer x) {
  return os << std::dec << x.getValue();
}




// owned
static inline
Integer operator + (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv += yv; y.free(); return x; }
  if (y.refCount() == 1) { yv += xv; x.free(); return y; }
  Integer z(xv + yv);
  x.free(); y.free();
  return z;
}

// owned
static inline
Integer operator - (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv -= yv; y.free(); return x; }
  if (y.refCount() == 1) { yv = xv - yv; x.free(); return y; }
  Integer z(xv - yv);
  x.free(); y.free();
  return z;
}

// owned
static inline
Integer operator * (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv *= yv; y.free(); return x; }
  if (y.refCount() == 1) { yv *= xv; x.free(); return y; }
  Integer z(xv * yv);
  x.free(); y.free();
  return z;
}

// XXX: Check for division by 0?
// owned
static inline
Integer operator / (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv /= yv;     y.free(); return x; }
  if (y.refCount() == 1) { yv = xv / yv; x.free(); return y; }
  Integer z(xv / yv);
  x.free(); y.free();
  return z;
}


// XXX: Check for division by 0?
// owned
static inline
Integer operator % (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv %= yv;     y.free(); return x; }
  if (y.refCount() == 1) { yv = xv % yv; x.free(); return y; }
  Integer z(xv % yv);
  x.free(); y.free();
  return z;
}

static inline
// owned
Integer operator - (Integer x) {
  mpz_class &v = x.getValue();
  if (x.refCount() == 1) { v = -v; return x; }
  Integer y(-v);
  x.free();
  return y;
}



// owned, unmanaged
static inline
Integer operator << (Integer x, Size iamt) {
  size_t amt = iamt.rep();
  mpz_class &v = x.getValue();
  if (x.refCount() == 1) { x.mutShiftL(amt); return x; }
  Integer y(v << amt);
  x.free();
  return y;
}

// owned, unmanaged
static inline
Integer operator >> (Integer x, Size iamt) {
  size_t amt = iamt.rep();
  mpz_class &v = x.getValue();
  if (x.refCount() == 1) { x.mutShiftR(amt); return x; }
  Integer y(v >> amt);
  x.free();
  return y;
}


// owned
static inline
Integer operator | (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv |= yv;     y.free(); return x; }
  if (y.refCount() == 1) { yv = xv | yv; x.free(); return y; }
  Integer z(xv | yv);
  x.free(); y.free();
  return z;
}

// owned
static inline
Integer operator & (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv &= yv;     y.free(); return x; }
  if (y.refCount() == 1) { yv = xv & yv; x.free(); return y; }
  Integer z(xv & yv);
  x.free(); y.free();
  return z;
}


// owned
static inline
Integer operator ^ (Integer x, Integer y) {
  mpz_class &xv = x.getValue();
  mpz_class &yv = y.getValue();
  if (x.refCount() == 1) { xv ^= yv;     y.free(); return x; }
  if (y.refCount() == 1) { yv = xv ^ yv; x.free(); return y; }
  Integer z(xv ^ yv);
  x.free(); y.free();
  return z;
}









// NOTE: lcat is in `number.h` to avoid dependency conflicts
// Temprary shift with UInt<64> are also there for the same reason



}
#endif



#endif


