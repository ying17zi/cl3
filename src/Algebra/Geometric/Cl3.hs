{-# LANGUAGE Safe #-}
{-# LANGUAGE GADTSyntax #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}



--------------------------------------------------------------------------------------------
-- |
-- Copyright   :  (C) 2018 Nathan Waivio
-- License     :  BSD3
-- Maintainer  :  Nathan Waivio <nathan.waivio@gmail.com>
-- Stability   :  Stable
-- Portability :  unportable
--
-- Library implementing standard functions for the <https://en.wikipedia.org/wiki/Algebra_of_physical_space Algebra of Physical Space> Cl(3,0)
-- 
---------------------------------------------------------------------------------------------


module Algebra.Geometric.Cl3
(-- * The type for the Algebra of Physical Space
 Cl3(..),
 -- * Clifford Conjugate and Complex Conjugate
 bar, dag,
 -- * The littlest singular value
 lsv,
 -- * Constructor Selectors - For optimizing and simplifying calculations
 toR, toV3, toBV, toI,
 toPV, toH, toC,
 toBPV, toODD, toTPV,
 toAPS,
 -- * Pretty Printing for use with Octave
 showOctave,
 -- * Eliminate grades that are less than 'tol' to use a simpler Constructor
 reduce, tol,
 -- * Random Instances
 randR, rangeR,
 randV3, rangeV3,
 randBV, rangeBV,
 randI, rangeI,
 randPV, rangePV,
 randH, rangeH,
 randC, rangeC,
 randBPV, rangeBPV,
 randODD, rangeODD,
 randTPV, rangeTPV,
 randAPS, rangeAPS,
 randUnitV3,
 randProjector,
 randNilpotent,
 -- * Helpful Functions
 eigvals, hasNilpotent,
 spectraldcmp, project
) where


import Data.Data (Typeable, Data)
import GHC.Generics (Generic)
import Foreign.Storable (Storable, sizeOf, alignment, peek, poke)
import Foreign.Ptr (Ptr, plusPtr, castPtr)
import System.Random (RandomGen, Random, randomR, random)


-- | Cl3 provides specialized constructors for sub-algebras and other geometric objects
-- contained in the algebra.  Cl(3,0), abbreviated to Cl3, is a Geometric Algebra
-- of 3 dimensional space known as the Algebra of Physical Space (APS).  Geometric Algebras are Real
-- Clifford Algebras, double precision floats are used to approximate real numbers in this
-- library.  Single and Double grade combinations are specialized and live within the APS.
--
--   * 'R' is the constructor for the Real Scalar Sub-algebra Grade-0
--
--   * 'V3' is the Vector constructor Grade-1
--
--   * 'BV' is the Bivector constructor Grade-2
--
--   * 'I' is the Imaginary constructor Grade-3 and is the Pseudo-Scalar for APS
--
--   * 'PV' is the Paravector constructor with Grade-0 and Grade-1 elements
--
--   * 'H' is the Quaternion constructor it is the Even Sub-algebra with Grade-0 and Grade-2 elements
--
--   * 'C' is the Complex constructor it is the Scalar Sub-algebra with Grade-0 and Grade-3 elements
--
--   * 'BPV' is the Biparavector constructor with Grade-1 and Grade-2 elements
--
--   * 'ODD' is the Odd constructor with Grade-1 and Grade-3 elements
--
--   * 'TPV' is the Triparavector constructor with Grade-2 and Grade-3 elements
--
--   * 'APS' is the constructor for an element in the Algebra of Physical Space with Grade-0 through Grade-3 elements
--
data Cl3 where
  R   :: !Double -> Cl3 -- Real Scalar Sub-algebra (G0)
  V3  :: !Double -> !Double -> !Double -> Cl3 -- Vectors (G1)
  BV  :: !Double -> !Double -> !Double -> Cl3 -- Bivectors (G2)
  I   :: !Double -> Cl3 -- Trivector Imaginary Pseudo-Scalar (G3)
  PV  :: !Double -> !Double -> !Double -> !Double -> Cl3 -- Paravector (G0 + G1)
  H   :: !Double -> !Double -> !Double -> !Double -> Cl3 -- Quaternion Even Sub-algebra (G0 + G2)
  C   :: !Double -> !Double -> Cl3 -- Complex Sub-algebra (G0 + G3)
  BPV :: !Double -> !Double -> !Double -> !Double -> !Double -> !Double -> Cl3 -- Biparavector (G1 + G2)
  ODD :: !Double -> !Double -> !Double -> !Double -> Cl3 -- Odd (G1 + G3)
  TPV :: !Double -> !Double -> !Double -> !Double -> Cl3 -- Triparavector (G2 + G3)
  APS :: !Double -> !Double -> !Double -> !Double -> !Double -> !Double -> !Double -> !Double -> Cl3 -- Algebra of Physical Space (G0 + G1 + G2 + G3)
    deriving (Show, Read, Typeable, Data, Generic)



-- |'showOctave' for useful for debug purposes.
-- The additional octave definition is needed:  
-- 
-- > e0 = [1,0;0,1]; e1=[0,1;1,0]; e2=[0,-i;i,0]; e3=[1,0;0,-1];
--
-- This allows one to take advantage of the isomorphism between Cl3 and M(2,C)
showOctave :: Cl3 -> String
showOctave (R a0) = show a0 ++ "*e0"
showOctave (V3 a1 a2 a3) = show a1 ++ "*e1 + " ++ show a2 ++ "*e2 + " ++ show a3 ++ "*e3"
showOctave (BV a23 a31 a12) = show a23 ++ "i*e1 + " ++ show a31 ++ "i*e2 + " ++ show a12 ++ "i*e3"
showOctave (I a123) = show a123 ++ "i*e0"
showOctave (PV a0 a1 a2 a3) = show a0 ++ "*e0 + " ++ show a1 ++ "*e1 + " ++ show a2 ++ "*e2 + " ++ show a3 ++ "*e3"
showOctave (H a0 a23 a31 a12) = show a0 ++ "*e0 + " ++ show a23 ++ "i*e1 + " ++ show a31 ++ "i*e2 + " ++ show a12 ++ "i*e3"
showOctave (C a0 a123) = show a0 ++ "*e0 + " ++ show a123 ++ "i*e0"
showOctave (BPV a1 a2 a3 a23 a31 a12) = show a1 ++ "*e1 + " ++ show a2 ++ "*e2 + " ++ show a3 ++ "*e3 + " ++
                                        show a23 ++ "i*e1 + " ++ show a31 ++ "i*e2 + " ++ show a12 ++ "i*e3"
showOctave (ODD a1 a2 a3 a123) = show a1 ++ "*e1 + " ++ show a2 ++ "*e2 + " ++ show a3 ++ "*e3 + " ++ show a123 ++ "i*e0"
showOctave (TPV a23 a31 a12 a123) = show a23 ++ "i*e1 + " ++ show a31 ++ "i*e2 + " ++ show a12 ++ "i*e3 + " ++ show a123 ++ "i*e0"
showOctave (APS a0 a1 a2 a3 a23 a31 a12 a123) = show a0 ++ "*e0 + " ++ show a1 ++ "*e1 + " ++ show a2 ++ "*e2 + " ++ show a3 ++ "*e3 + " ++
                                                show a23 ++ "i*e1 + " ++ show a31 ++ "i*e2 + " ++ show a12 ++ "i*e3 + " ++ show a123 ++ "i*e0"


-- |Cl(3,0) has the property of equivalence.  "Eq" is "True" when all of the grade elements are equivalent.
instance Eq Cl3 where
  (R a0) == (R b0) = a0 == b0

  (R a0) == (V3 b1 b2 b3) = a0 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (R a0) == (BV b23 b31 b12) = a0 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (R a0) == (I b123) = a0 == 0 && b123 == 0
  (R a0) == (PV b0 b1 b2 b3) = a0 == b0 && b1 == 0 && b2 == 0 && b3 == 0
  (R a0) == (H b0 b23 b31 b12) = a0 == b0 && b23 == 0 && b31 == 0 && b12 == 0
  (R a0) == (C b0 b123) = a0 == b0 && b123 == 0
  (R a0) == (BPV b1 b2 b3 b23 b31 b12) = a0 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (R a0) == (ODD b1 b2 b3 b123) = a0 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b123 == 0
  (R a0) == (TPV b23 b31 b12 b123) = a0 == 0 && b23 == 0 && b31 == 0 && b12 == 0 && b123 == 0
  (R a0) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a0 == b0 && b1 == 0 && b2 == 0 && b3 == 0 && b23 == 0 && b31 == 0 && b12 == 0 && b123 == 0

  (V3 a1 a2 a3) == (R b0) = a1 == 0 && a2 == 0 && a3 == 0 && b0 == 0
  (BV a23 a31 a12) == (R b0) = a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0
  (I a123) == (R b0) = a123 == 0 && b0 == 0
  (PV a0 a1 a2 a3) == (R b0) = a0 == b0 && a1 == 0 && a2 == 0 && a3 == 0
  (H a0 a23 a31 a12) == (R b0) = a0 == b0 && a23 == 0 && a31 == 0 && a12 == 0
  (C a0 a123) == (R b0) = a0 == b0 && a123 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (R b0) = a1 == 0 && a2 == 0 && a3 == 0 && a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0
  (ODD a1 a2 a3 a123) == (R b0) = a1 == 0 && a2 == 0 && a3 == 0 && a123 == 0 && b0 == 0
  (TPV a23 a31 a12 a123) == (R b0) = a23 == 0 && a31 == 0 && a12 == 0 && a123 == 0 && b0 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (R b0) = a0 == b0 && a1 == 0 && a2 == 0 && a3 == 0 && a23 == 0 && a31 == 0 && a12 == 0 && a123 == 0

  (V3 a1 a2 a3) == (V3 b1 b2 b3) = a1 == b1 && a2 == b2 && a3 == b3

  (V3 a1 a2 a3) == (BV b23 b31 b12) = a1 == 0 && a2 == 0 && a3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (V3 a1 a2 a3) == (I b123) = a1 == 0 && a2 == 0 && a3 == 0 && b123 == 0
  (V3 a1 a2 a3) == (PV b0 b1 b2 b3) = a1 == b1 && a2 == b2 && a3 == b3 && b0 == 0
  (V3 a1 a2 a3) == (H b0 b23 b31 b12) = a1 == 0 && a2 == 0 && a3 == 0 && b0 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (V3 a1 a2 a3) == (C b0 b123) = a1 == 0 && a2 == 0 && a3 == 0 && b0 == 0 && b123 == 0
  (V3 a1 a2 a3) == (BPV b1 b2 b3 b23 b31 b12) = a1 == b1 && a2 == b2 && a3 == b3 && b23 == 0 && b31 == 0 && b12 == 0
  (V3 a1 a2 a3) == (ODD b1 b2 b3 b123) = a1 == b1 && a2 == b2 && a3 == b3 && b123 == 0
  (V3 a1 a2 a3) == (TPV b23 b31 b12 b123) = a1 == 0 && a2 == 0 && a3 == 0 && b23 == 0 && b31 == 0 && b12 == 0 && b123 == 0
  (V3 a1 a2 a3) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a1 == b1 && a2 == b2 && a3 == b3 && b0 == 0 && b23 == 0 && b31 == 0 && b12 == 0 && b123 == 0

  (BV a23 a31 a12) == (V3 b1 b2 b3) = a23 == 0 && a31 == 0 && a12 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (I a123) == (V3 b1 b2 b3) = a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (PV a0 a1 a2 a3) == (V3 b1 b2 b3) = a0 == 0 && a1 == b1 && a2 == b2 && a3 == b3
  (H a0 a23 a31 a12) == (V3 b1 b2 b3) = a0 == 0 && a23 == 0 && a31 == 0 && a12 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (C a0 a123) == (V3 b1 b2 b3) = a0 == 0 && a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (V3 b1 b2 b3) = a1 == b1 && a2 == b2 && a3 == b3 && a23 == 0 && a31 == 0 && a12 == 0
  (ODD a1 a2 a3 a123) == (V3 b1 b2 b3) = a1 == b1 && a2 == b2 && a3 == b3 && a123 == 0
  (TPV a23 a31 a12 a123) == (V3 b1 b2 b3) = b1 == 0 && b2 == 0 && b3 == 0 && a23 == 0 && a31 == 0 && a12 == 0 && a123 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (V3 b1 b2 b3) = a0 == 0 && a1 == b1 && a2 == b2 && a3 == b3 && a23 == 0 && a31 == 0 && a12 == 0 && a123 == 0

  (BV a23 a31 a12) == (BV b23 b31 b12) = a23 == b23 && a31 == b31 && a12 == b12

  (BV a23 a31 a12) == (I b123) = a23 == 0 && a31 == 0 && a12 == 0 && b123 == 0
  (BV a23 a31 a12) == (PV b0 b1 b2 b3) = a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (BV a23 a31 a12) == (H b0 b23 b31 b12) = a23 == b23 && a31 == b31 && a12 == b12 && b0 == 0
  (BV a23 a31 a12) == (C b0 b123) = a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0 && b123 == 0
  (BV a23 a31 a12) == (BPV b1 b2 b3 b23 b31 b12) = a23 == b23 && a31 == b31 && a12 == b12 && b1 == 0 && b2 == 0 && b3 == 0
  (BV a23 a31 a12) == (ODD b1 b2 b3 b123) = a23 == 0 && a31 == 0 && a12 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b123 == 0
  (BV a23 a31 a12) == (TPV b23 b31 b12 b123) = a23 == b23 && a31 == b31 && a12 == b12 && b123 == 0
  (BV a23 a31 a12) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a23 == b23 && a31 == b31 && a12 == b12 && b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b123 == 0

  (I a123) == (BV b23 b31 b12) = a123 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (PV a0 a1 a2 a3) == (BV b23 b31 b12) = a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (H a0 a23 a31 a12) == (BV b23 b31 b12) = a0 == 0 && a23 == b23 && a31 == b31 && a12 == b12
  (C a0 a123) == (BV b23 b31 b12) = a0 == 0 && a123 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (BV b23 b31 b12) = a1 == 0 && a2 == 0 && a3 == 0 && a23 == b23 && a31 == b31 && a12 == b12
  (ODD a1 a2 a3 a123) == (BV b23 b31 b12) = a1 == 0 && a2 == 0 && a3 == 0 && a123 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (TPV a23 a31 a12 a123) == (BV b23 b31 b12) = a23 == b23 && a31 == b31 && a12 == b12 && a123 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (BV b23 b31 b12) = a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0 && a23 == b23 && a31 == b31 && a12 == b12 && a123 == 0

  (I a123) == (I b123) = a123 == b123

  (I a123) == (PV b0 b1 b2 b3) = a123 == 0 && b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (I a123) == (H b0 b23 b31 b12) = a123 == 0 && b0 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (I a123) == (C b0 b123) = a123 == b123 && b0 == 0
  (I a123) == (BPV b1 b2 b3 b23 b31 b12) = a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (I a123) == (ODD b1 b2 b3 b123) = a123 == b123 && b1 == 0 && b2 == 0 && b3 == 0
  (I a123) == (TPV b23 b31 b12 b123) = a123 == b123 && b23 == 0 && b31 == 0 && b12 == 0
  (I a123) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a123 == b123 && b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b23 == 0 && b31 == 0 && b12 == 0

  (PV a0 a1 a2 a3) == (I b123) = b123 == 0 && a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0
  (H a0 a23 a31 a12) == (I b123) = b123 == 0 && a0 == 0 && a23 == 0 && a31 == 0 && a12 == 0
  (C a0 a123) == (I b123) = a123 == b123 && a0 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (I b123) = b123 == 0 && a1 == 0 && a2 == 0 && a3 == 0 && a23 == 0 && a31 == 0 && a12 == 0
  (ODD a1 a2 a3 a123) == (I b123) = a123 == b123 && a1 == 0 && a2 == 0 && a3 == 0
  (TPV a23 a31 a12 a123) == (I b123) = a123 == b123 && a23 == 0 && a31 == 0 && a12 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (I b123) = a123 == b123 && a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0 && a23 == 0 && a31 == 0 && a12 == 0

  (PV a0 a1 a2 a3) == (PV b0 b1 b2 b3) = a0 == b0 && a1 == b1 && a2 == b2 && a3 == b3

  (PV a0 a1 a2 a3) == (H b0 b23 b31 b12) = a0 == b0 && a1 == 0 && a2 == 0 && a3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (PV a0 a1 a2 a3) == (C b0 b123) = a0 == b0 && a1 == 0 && a2 == 0 && a3 == 0 && b123 == 0
  (PV a0 a1 a2 a3) == (BPV b1 b2 b3 b23 b31 b12) = a0 == 0 && a1 == b1 && a2 == b2 && a3 == b3 && b23 == 0 && b31 == 0 && b12 == 0
  (PV a0 a1 a2 a3) == (ODD b1 b2 b3 b123) = a0 == 0 && a1 == b1 && a2 == b2 && a3 == b3 && b123 == 0
  (PV a0 a1 a2 a3) == (TPV b23 b31 b12 b123) = a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0 && b23 == 0 && b31 == 0 && b12 == 0 && b123 == 0
  (PV a0 a1 a2 a3) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a0 == b0 && a1 == b1 && a2 == b2 && a3 == b3 && b23 == 0 && b31 == 0 && b12 == 0 && b123 == 0

  (H a0 a23 a31 a12) == (PV b0 b1 b2 b3) = a0 == b0 && a23 == 0 && a31 == 0 && a12 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (C a0 a123) == (PV b0 b1 b2 b3) = a0 == b0 && a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (PV b0 b1 b2 b3) = a1 == b1 && a2 == b2 && a3 == b3 && a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0
  (ODD a1 a2 a3 a123) == (PV b0 b1 b2 b3) = a1 == b1 && a2 == b2 && a3 == b3 && a123 == 0 && b0 == 0
  (TPV a23 a31 a12 a123) == (PV b0 b1 b2 b3) = a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0 && a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (PV b0 b1 b2 b3) = a0 == b0 && a1 == b1 && a2 == b2 && a3 == b3 && a23 == 0 && a31 == 0 && a12 == 0 && a123 == 0

  (H a0 a23 a31 a12) == (H b0 b23 b31 b12) = a0 == b0 && a23 == b23 && a31 == b31 && a12 == b12

  (H a0 a23 a31 a12) == (C b0 b123) = a0 == b0 && a23 == 0 && a31 == 0 && a12 == 0 && b123 == 0
  (H a0 a23 a31 a12) == (BPV b1 b2 b3 b23 b31 b12) = a0 == 0 && a23 == b23 && a31 == b31 && a12 == b12 && b1 == 0 && b2 == 0 && b3 == 0
  (H a0 a23 a31 a12) == (ODD b1 b2 b3 b123) = a0 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && a23 == 0 && a31 == 0 && a12 == 0 && b123 == 0
  (H a0 a23 a31 a12) == (TPV b23 b31 b12 b123) = a0 == 0 && a23 == b23 && a31 == b31 && a12 == b12 && b123 == 0
  (H a0 a23 a31 a12) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a0 == b0 && a23 == b23 && a31 == b31 && a12 == b12 && b1 == 0 && b2 == 0 && b3 == 0 && b123 == 0

  (C a0 a123) == (H b0 b23 b31 b12) = a0 == b0 && a123 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (H b0 b23 b31 b12) = a1 == 0 && a2 == 0 && a3 == 0 && a23 == b23 && a31 == b31 && a12 == b12 && b0 == 0
  (ODD a1 a2 a3 a123) == (H b0 b23 b31 b12) = a1 == 0 && a2 == 0 && a3 == 0 && a123 == 0 && b23 == 0 && b31 == 0 && b12 == 0 && b0 == 0
  (TPV a23 a31 a12 a123) == (H b0 b23 b31 b12) = a23 == b23 && a31 == b31 && a12 == b12 && b0 == 0 && a123 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (H b0 b23 b31 b12) = a0 == b0 && a1 == 0 && a2 == 0 && a3 == 0 && a23 == b23 && a31 == b31 && a12 == b12 && a123 == 0

  (C a0 a123) == (C b0 b123) = a0 == b0 && a123 == b123

  (C a0 a123) == (BPV b1 b2 b3 b23 b31 b12) = a0 == 0 && a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (C a0 a123) == (ODD b1 b2 b3 b123) = a0 == 0 && a123 == b123 && b1 == 0 && b2 == 0 && b3 == 0
  (C a0 a123) == (TPV b23 b31 b12 b123) = a0 == 0 && a123 == b123 && b23 == 0 && b31 == 0 && b12 == 0
  (C a0 a123) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a0 == b0 && a123 == b123 && b1 == 0 && b2 == 0 && b3 == 0 && b23 == 0 && b31 == 0 && b12 == 0

  (BPV a1 a2 a3 a23 a31 a12) == (C b0 b123) = a1 == 0 && a2 == 0 && a3 == 0 && a23 == 0 && a31 == 0 && a12 == 0 && b0 == 0 && b123 == 0
  (ODD a1 a2 a3 a123) == (C b0 b123) = b0 == 0 && a123 == b123 && a1 == 0 && a2 == 0 && a3 == 0
  (TPV a23 a31 a12 a123) == (C b0 b123) = b0 == 0 && a123 == b123 && a23 == 0 && a31 == 0 && a12 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (C b0 b123) = a0 == b0 && a123 == b123 && a1 == 0 && a2 == 0 && a3 == 0 && a23 == 0 && a31 == 0 && a12 == 0

  (BPV a1 a2 a3 a23 a31 a12) == (BPV b1 b2 b3 b23 b31 b12) = a1 == b1 && a2 == b2 && a3 == b3 && a23 == b23 && a31 == b31 && a12 == b12

  (BPV a1 a2 a3 a23 a31 a12) == (ODD b1 b2 b3 b123) = a1 == b1 && a2 == b2 && a3 == b3 && b123 == 0 && a23 == 0 && a31 == 0 && a12 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (TPV b23 b31 b12 b123) = a23 == b23 && a31 == b31 && a12 == b12 && b123 == 0 && a1 == 0 && a2 == 0 && a3 == 0
  (BPV a1 a2 a3 a23 a31 a12) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a1 == b1 && a2 == b2 && a3 == b3 && a23 == b23 && a31 == b31 && a12 == b12
                                                                              && b0 == 0 && b123 == 0

  (ODD a1 a2 a3 a123) == (BPV b1 b2 b3 b23 b31 b12) = a1 == b1 && a2 == b2 && a3 == b3 && a123 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (TPV a23 a31 a12 a123) == (BPV b1 b2 b3 b23 b31 b12) = a23 == b23 && a31 == b31 && a12 == b12 && a123 == 0 && b1 == 0 && b2 == 0 && b3 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (BPV b1 b2 b3 b23 b31 b12) = a0 == 0 && a1 == b1 && a2 == b2 && a3 == b3 && a23 == b23 && a31 == b31
                                                                             && a12 == b12 && a123 == 0

  (ODD a1 a2 a3 a123) == (ODD b1 b2 b3 b123) = a1 == b1 && a2 == b2 && a3 == b3 && a123 == b123

  (ODD a1 a2 a3 a123) == (TPV b23 b31 b12 b123) = a123 == b123 && a1 == 0 && a2 == 0 && a3 == 0 && b23 == 0 && b31 == 0 && b12 == 0
  (ODD a1 a2 a3 a123) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a1 == b1 && a2 == b2 && a3 == b3 && a123 == b123 && b0 == 0 && b23 == 0 && b31 == 0 && b12 == 0

  (TPV a23 a31 a12 a123) == (ODD b1 b2 b3 b123) = a123 == b123 && b1 == 0 && b2 == 0 && b3 == 0 && a23 == 0 && a31 == 0 && a12 == 0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (ODD b1 b2 b3 b123) = a1 == b1 && a2 == b2 && a3 == b3 && a123 == b123 && a0 == 0 && a23 == 0 && a31 == 0 && a12 == 0

  (TPV a23 a31 a12 a123) == (TPV b23 b31 b12 b123) = a23 == b23 && a31 == b31 && a12 == b12 && a123 == b123

  (TPV a23 a31 a12 a123) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a23 == b23 && a31 == b31 && a12 == b12 && a123 == b123
                                                                            && b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0

  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (TPV b23 b31 b12 b123) = a23 == b23 && a31 == b31 && a12 == b12 && a123 == b123
                                                                            && a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0

  (APS a0 a1 a2 a3 a23 a31 a12 a123) == (APS b0 b1 b2 b3 b23 b31 b12 b123) = a0 == b0 && a1 == b1 && a2 == b2 && a3 == b3 && a23 == b23
                                                                                      && a31 == b31 && a12 == b12 && a123 == b123


-- |Cl3 has a total preorder ordering in which all pairs are comparable by two real valued functions.
-- Comparison of two reals is just the typical real compare function.  When reals are compared to
-- anything else it will compare the absolute value of the reals to the magnitude of the other cliffor.
-- Compare of two complex values compares the polar magnitude of the complex numbers.  Compare of 
-- two vectors compares the vector magnitudes.  The Ord instance for the general case is based on 
-- the singular values of each cliffor and this Ordering compares the largest singular value 'abs' 
-- and then the littlest singular value 'lsv'.  Some arbitrary cliffors may return EQ for Ord but not be 
-- exactly '==' equivalent, but they are related by a right and left multiplication of two unitary 
-- elements.  For instance for the Cliffors A and B, A == B could be False, but compare A B is EQ, 
-- because A * V = U * B, where V and U are unitary.  
instance Ord Cl3 where
  compare (R a0) (R b0) = compare a0 b0
  compare cliffor1 cliffor2 =
     let (R a0) = abs cliffor1
         (R b0) = abs cliffor2
     in case compare a0 b0 of
          EQ -> let (R a0') = lsv cliffor1
                    (R b0') = lsv cliffor2
                in compare a0' b0'
          LT -> LT
          GT -> GT


-- |Cl3 has a "Num" instance.  "Num" is addition, geometric product, negation, 'abs' the largest
-- singular value, and 'signum' like a unit vector of sorts.
-- 
instance Num Cl3 where
  -- | Cl3 can be added
  (R a0) + (R b0) = R (a0 + b0)

  (R a0) + (V3 b1 b2 b3) = PV a0 b1 b2 b3
  (R a0) + (BV b23 b31 b12) = H a0 b23 b31 b12
  (R a0) + (I b123) = C a0 b123
  (R a0) + (PV b0 b1 b2 b3) = PV (a0 + b0) b1 b2 b3
  (R a0) + (H b0 b23 b31 b12) = H (a0 + b0) b23 b31 b12
  (R a0) + (C b0 b123) = C (a0 + b0) b123
  (R a0) + (BPV b1 b2 b3 b23 b31 b12) = APS a0 b1 b2 b3 b23 b31 b12 0
  (R a0) + (ODD b1 b2 b3 b123) = APS a0 b1 b2 b3 0 0 0 b123
  (R a0) + (TPV b23 b31 b12 b123) = APS a0 0 0 0 b23 b31 b12 b123
  (R a0) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0 + b0) b1 b2 b3 b23 b31 b12 b123

  (V3 a1 a2 a3) + (R b0) = PV b0 a1 a2 a3
  (BV a23 a31 a12) + (R b0) = H b0 a23 a31 a12
  (I a123) + (R b0) = C b0 a123
  (PV a0 a1 a2 a3) + (R b0) = PV (a0 + b0) a1 a2 a3
  (H a0 a23 a31 a12) + (R b0) = H (a0 + b0) a23 a31 a12
  (C a0 a123) + (R b0) = C (a0 + b0) a123
  (BPV a1 a2 a3 a23 a31 a12) + (R b0) = APS b0 a1 a2 a3 a23 a31 a12 0
  (ODD a1 a2 a3 a123) + (R b0) = APS b0 a1 a2 a3 0 0 0 a123
  (TPV a23 a31 a12 a123) + (R b0) = APS b0 0 0 0 a23 a31 a12 a123
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (R b0) = APS (a0 + b0) a1 a2 a3 a23 a31 a12 a123

  (V3 a1 a2 a3) + (V3 b1 b2 b3) = V3 (a1 + b1) (a2 + b2) (a3 + b3)

  (V3 a1 a2 a3) + (BV b23 b31 b12) = BPV a1 a2 a3 b23 b31 b12
  (V3 a1 a2 a3) + (I b123) = ODD a1 a2 a3 b123
  (V3 a1 a2 a3) + (PV b0 b1 b2 b3) = PV b0 (a1 + b1) (a2 + b2) (a3 + b3)
  (V3 a1 a2 a3) + (H b0 b23 b31 b12) = APS b0 a1 a2 a3 b23 b31 b12 0
  (V3 a1 a2 a3) + (C b0 b123) = APS b0 a1 a2 a3 0 0 0 b123
  (V3 a1 a2 a3) + (BPV b1 b2 b3 b23 b31 b12) = BPV (a1 + b1) (a2 + b2) (a3 + b3) b23 b31 b12
  (V3 a1 a2 a3) + (ODD b1 b2 b3 b123) = ODD (a1 + b1) (a2 + b2) (a3 + b3) b123
  (V3 a1 a2 a3) + (TPV b23 b31 b12 b123) = APS 0 a1 a2 a3 b23 b31 b12 b123
  (V3 a1 a2 a3) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS b0 (a1 + b1) (a2 + b2) (a3 + b3) b23 b31 b12 b123

  (BV a23 a31 a12) + (V3 b1 b2 b3) = BPV b1 b2 b3 a23 a31 a12
  (I a123) + (V3 b1 b2 b3) = ODD b1 b2 b3 a123
  (PV a0 a1 a2 a3) + (V3 b1 b2 b3) = PV a0 (a1 + b1) (a2 + b2) (a3 + b3)
  (H a0 a23 a31 a12) + (V3 b1 b2 b3) = APS a0 b1 b2 b3 a23 a31 a12 0
  (C a0 a123) + (V3 b1 b2 b3) = APS a0 b1 b2 b3 0 0 0 a123
  (BPV a1 a2 a3 a23 a31 a12) + (V3 b1 b2 b3) = BPV (a1 + b1) (a2 + b2) (a3 + b3) a23 a31 a12
  (ODD a1 a2 a3 a123) + (V3 b1 b2 b3) = ODD (a1 + b1) (a2 + b2) (a3 + b3) a123
  (TPV a23 a31 a12 a123) + (V3 b1 b2 b3) = APS 0 b1 b2 b3 a23 a31 a12 a123
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (V3 b1 b2 b3) = APS a0 (a1 + b1) (a2 + b2) (a3 + b3) a23 a31 a12 a123

  (BV a23 a31 a12) + (BV b23 b31 b12) = BV (a23 + b23) (a31 + b31) (a12 + b12)

  (BV a23 a31 a12) + (I b123) = TPV a23 a31 a12 b123
  (BV a23 a31 a12) + (PV b0 b1 b2 b3) = APS b0 b1 b2 b3 a23 a31 a12 0
  (BV a23 a31 a12) + (H b0 b23 b31 b12) = H b0 (a23 + b23) (a31 + b31) (a12 + b12)
  (BV a23 a31 a12) + (C b0 b123) = APS b0 0 0 0 a23 a31 a12 b123
  (BV a23 a31 a12) + (BPV b1 b2 b3 b23 b31 b12) = BPV b1 b2 b3 (a23 + b23) (a31 + b31) (a12 + b12)
  (BV a23 a31 a12) + (ODD b1 b2 b3 b123) = APS 0 b1 b2 b3 a23 a31 a12 b123
  (BV a23 a31 a12) + (TPV b23 b31 b12 b123) = TPV (a23 + b23) (a31 + b31) (a12 + b12) b123
  (BV a23 a31 a12) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS b0 b1 b2 b3 (a23 + b23) (a31 + b31) (a12 + b12) b123

  (I a123) + (BV b23 b31 b12) = TPV b23 b31 b12 a123
  (PV a0 a1 a2 a3) + (BV b23 b31 b12) = APS a0 a1 a2 a3 b23 b31 b12 0
  (H a0 a23 a31 a12) + (BV b23 b31 b12) = H a0 (a23 + b23) (a31 + b31) (a12 + b12)
  (C a0 a123) + (BV b23 b31 b12) = APS a0 0 0 0 b23 b31 b12 a123
  (BPV a1 a2 a3 a23 a31 a12) + (BV b23 b31 b12) = BPV a1 a2 a3 (a23 + b23) (a31 + b31) (a12 + b12)
  (ODD a1 a2 a3 a123) + (BV b23 b31 b12) = APS 0 a1 a2 a3 b23 b31 b12 a123
  (TPV a23 a31 a12 a123) + (BV b23 b31 b12) = TPV (a23 + b23) (a31 + b31) (a12 + b12) a123
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (BV b23 b31 b12) = APS a0 a1 a2 a3 (a23 + b23) (a31 + b31) (a12 + b12) a123

  (I a123) + (I b123) = I (a123 + b123)

  (I a123) + (PV b0 b1 b2 b3) = APS b0 b1 b2 b3 0 0 0 a123
  (I a123) + (H b0 b23 b31 b12) = APS b0 0 0 0 b23 b31 b12 a123
  (I a123) + (C b0 b123) = C b0 (a123 + b123)
  (I a123) + (BPV b1 b2 b3 b23 b31 b12) = APS 0 b1 b2 b3 b23 b31 b12 a123
  (I a123) + (ODD b1 b2 b3 b123) = ODD b1 b2 b3 (a123 + b123)
  (I a123) + (TPV b23 b31 b12 b123) = TPV b23 b31 b12 (a123 + b123)
  (I a123) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS b0 b1 b2 b3 b23 b31 b12 (a123 + b123)

  (PV a0 a1 a2 a3) + (I b123) = APS a0 a1 a2 a3 0 0 0 b123
  (H a0 a23 a31 a12) + (I b123) = APS a0 0 0 0 a23 a31 a12 b123
  (C a0 a123) + (I b123) = C a0 (a123 + b123)
  (BPV a1 a2 a3 a23 a31 a12) + (I b123) = APS 0 a1 a2 a3 a23 a31 a12 b123
  (ODD a1 a2 a3 a123) + (I b123) = ODD a1 a2 a3 (a123 + b123)
  (TPV a23 a31 a12 a123) + (I b123) = TPV a23 a31 a12 (a123 + b123)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (I b123) = APS a0 a1 a2 a3 a23 a31 a12 (a123 + b123)

  (PV a0 a1 a2 a3) + (PV b0 b1 b2 b3) = PV (a0 + b0) (a1 + b1) (a2 + b2) (a3 + b3)

  (PV a0 a1 a2 a3) + (H b0 b23 b31 b12) = APS (a0 + b0) a1 a2 a3 b23 b31 b12 0
  (PV a0 a1 a2 a3) + (C b0 b123) = APS (a0 + b0) a1 a2 a3 0 0 0 b123
  (PV a0 a1 a2 a3) + (BPV b1 b2 b3 b23 b31 b12) = APS a0 (a1 + b1) (a2 + b2) (a3 + b3) b23 b31 b12 0
  (PV a0 a1 a2 a3) + (ODD b1 b2 b3 b123) = APS a0 (a1 + b1) (a2 + b2) (a3 + b3) 0 0 0 b123
  (PV a0 a1 a2 a3) + (TPV b23 b31 b12 b123) = APS a0 a1 a2 a3 b23 b31 b12 b123
  (PV a0 a1 a2 a3) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0 + b0) (a1 + b1) (a2 + b2) (a3 + b3) b23 b31 b12 b123

  (H a0 a23 a31 a12) + (PV b0 b1 b2 b3) = APS (a0 + b0) b1 b2 b3 a23 a31 a12 0
  (C a0 a123) + (PV b0 b1 b2 b3) = APS (a0 + b0) b1 b2 b3 0 0 0 a123
  (BPV a1 a2 a3 a23 a31 a12) + (PV b0 b1 b2 b3) = APS b0 (a1 + b1) (a2 + b2) (a3 + b3) a23 a31 a12 0
  (ODD a1 a2 a3 a123) + (PV b0 b1 b2 b3) = APS b0 (a1 + b1) (a2 + b2) (a3 + b3) 0 0 0 a123
  (TPV a23 a31 a12 a123) + (PV b0 b1 b2 b3) = APS b0 b1 b2 b3 a23 a31 a12 a123
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (PV b0 b1 b2 b3) = APS (a0 + b0) (a1 + b1) (a2 + b2) (a3 + b3) a23 a31 a12 a123

  (H a0 a23 a31 a12) + (H b0 b23 b31 b12) = H (a0 + b0) (a23 + b23) (a31 + b31) (a12 + b12)

  (H a0 a23 a31 a12) + (C b0 b123) = APS (a0 + b0) 0 0 0 a23 a31 a12 b123
  (H a0 a23 a31 a12) + (BPV b1 b2 b3 b23 b31 b12) = APS a0 b1 b2 b3 (a23 + b23) (a31 + b31) (a12 + b12) 0
  (H a0 a23 a31 a12) + (ODD b1 b2 b3 b123) = APS a0 b1 b2 b3 a23 a31 a12 b123
  (H a0 a23 a31 a12) + (TPV b23 b31 b12 b123) = APS a0 0 0 0 (a23 + b23) (a31 + b31) (a12 + b12) b123
  (H a0 a23 a31 a12) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0 + b0) b1 b2 b3 (a23 + b23) (a31 + b31) (a12 + b12) b123

  (C a0 a123) + (H b0 b23 b31 b12) = APS (a0 + b0) 0 0 0 b23 b31 b12 a123
  (BPV a1 a2 a3 a23 a31 a12) + (H b0 b23 b31 b12) = APS b0 a1 a2 a3 (a23 + b23) (a31 + b31) (a12 + b12) 0
  (ODD a1 a2 a3 a123) + (H b0 b23 b31 b12) = APS b0 a1 a2 a3 b23 b31 b12 a123
  (TPV a23 a31 a12 a123) + (H b0 b23 b31 b12) = APS b0 0 0 0 (a23 + b23) (a31 + b31) (a12 + b12) a123
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (H b0 b23 b31 b12) = APS (a0 + b0) a1 a2 a3 (a23 + b23) (a31 + b31) (a12 + b12) a123

  (C a0 a123) + (C b0 b123) = C (a0 + b0) (a123 + b123)

  (C a0 a123) + (BPV b1 b2 b3 b23 b31 b12) = APS a0 b1 b2 b3 b23 b31 b12 a123
  (C a0 a123) + (ODD b1 b2 b3 b123) = APS a0 b1 b2 b3 0 0 0 (a123 + b123)
  (C a0 a123) + (TPV b23 b31 b12 b123) = APS a0 0 0 0 b23 b31 b12 (a123 + b123)
  (C a0 a123) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0 + b0) b1 b2 b3 b23 b31 b12 (a123 + b123)

  (BPV a1 a2 a3 a23 a31 a12) + (C b0 b123) = APS b0 a1 a2 a3 a23 a31 a12 b123
  (ODD a1 a2 a3 a123) + (C b0 b123) = APS b0 a1 a2 a3 0 0 0 (a123 + b123)
  (TPV a23 a31 a12 a123) + (C b0 b123) = APS b0 0 0 0 a23 a31 a12 (a123 + b123)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (C b0 b123) = APS (a0 + b0) a1 a2 a3 a23 a31 a12 (a123 + b123)

  (BPV a1 a2 a3 a23 a31 a12) + (BPV b1 b2 b3 b23 b31 b12) = BPV (a1 + b1) (a2 + b2) (a3 + b3) (a23 + b23) (a31 + b31) (a12 + b12)

  (BPV a1 a2 a3 a23 a31 a12) + (ODD b1 b2 b3 b123) = APS 0 (a1 + b1) (a2 + b2) (a3 + b3) a23 a31 a12 b123
  (BPV a1 a2 a3 a23 a31 a12) + (TPV b23 b31 b12 b123) = APS 0 a1 a2 a3 (a23 + b23) (a31 + b31) (a12 + b12) b123
  (BPV a1 a2 a3 a23 a31 a12) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS b0 (a1 + b1) (a2 + b2) (a3 + b3) (a23 + b23) (a31 + b31) (a12 + b12) b123

  (ODD a1 a2 a3 a123) + (BPV b1 b2 b3 b23 b31 b12) = APS 0 (a1 + b1) (a2 + b2) (a3 + b3) b23 b31 b12 a123
  (TPV a23 a31 a12 a123) + (BPV b1 b2 b3 b23 b31 b12) = APS 0 b1 b2 b3 (a23 + b23) (a31 + b31) (a12 + b12) a123
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (BPV b1 b2 b3 b23 b31 b12) = APS a0 (a1 + b1) (a2 + b2) (a3 + b3) (a23 + b23) (a31 + b31) (a12 + b12) a123

  (ODD a1 a2 a3 a123) + (ODD b1 b2 b3 b123) = ODD (a1 + b1) (a2 + b2) (a3 + b3) (a123 + b123)

  (ODD a1 a2 a3 a123) + (TPV b23 b31 b12 b123) = APS 0 a1 a2 a3 b23 b31 b12 (a123 + b123)
  (ODD a1 a2 a3 a123) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS b0 (a1 + b1) (a2 + b2) (a3 + b3) b23 b31 b12 (a123 + b123)

  (TPV a23 a31 a12 a123) + (ODD b1 b2 b3 b123) = APS 0 b1 b2 b3 a23 a31 a12 (a123 + b123)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (ODD b1 b2 b3 b123) = APS a0 (a1 + b1) (a2 + b2) (a3 + b3) a23 a31 a12 (a123 + b123)

  (TPV a23 a31 a12 a123) + (TPV b23 b31 b12 b123) = TPV (a23 + b23) (a31 + b31) (a12 + b12) (a123 + b123)

  (TPV a23 a31 a12 a123) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS b0 b1 b2 b3 (a23 + b23) (a31 + b31) (a12 + b12) (a123 + b123)

  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (TPV b23 b31 b12 b123) = APS a0 a1 a2 a3 (a23 + b23) (a31 + b31) (a12 + b12) (a123 + b123)

  (APS a0 a1 a2 a3 a23 a31 a12 a123) + (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0 + b0)
                                                                                (a1 + b1) (a2 + b2) (a3 + b3)
                                                                                (a23 + b23) (a31 + b31) (a12 + b12)
                                                                                (a123 + b123)

  -- | Multiplication Instance implementing a Geometric Product
  (R a0) * (R b0) = R (a0*b0)

  (R a0) * (V3 b1 b2 b3) = V3 (a0*b1) (a0*b2) (a0*b3)
  (R a0) * (BV b23 b31 b12) = BV (a0*b23) (a0*b31) (a0*b12)
  (R a0) * (I b123) = I (a0*b123)
  (R a0) * (PV b0 b1 b2 b3) = PV (a0*b0)
                                 (a0*b1) (a0*b2) (a0*b3)
  (R a0) * (H b0 b23 b31 b12) = H (a0*b0)
                                  (a0*b23) (a0*b31) (a0*b12)
  (R a0) * (C b0 b123) = C (a0*b0)
                           (a0*b123)
  (R a0) * (BPV b1 b2 b3 b23 b31 b12) = BPV (a0*b1) (a0*b2) (a0*b3)
                                            (a0*b23) (a0*b31) (a0*b12)
  (R a0) * (ODD b1 b2 b3 b123) = ODD (a0*b1) (a0*b2) (a0*b3)
                                     (a0*b123)
  (R a0) * (TPV b23 b31 b12 b123) = TPV (a0*b23) (a0*b31) (a0*b12)
                                        (a0*b123)
  (R a0) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0*b0)
                                                    (a0*b1) (a0*b2) (a0*b3)
                                                    (a0*b23) (a0*b31) (a0*b12)
                                                    (a0*b123)

  (V3 a1 a2 a3) * (R b0) = V3 (a1*b0) (a2*b0) (a3*b0)
  (BV a23 a31 a12) * (R b0) = BV (a23*b0) (a31*b0) (a12*b0)
  (I a123) * (R b0) = I (a123*b0)
  (PV a0 a1 a2 a3) * (R b0) = PV (a0*b0)
                                 (a1*b0) (a2*b0) (a3*b0)
  (H a0 a23 a31 a12) * (R b0) = H (a0*b0)
                                  (a23*b0) (a31*b0) (a12*b0)
  (C a0 a123) * (R b0) = C (a0*b0)
                           (a123*b0)
  (BPV a1 a2 a3 a23 a31 a12) * (R b0) = BPV (a1*b0) (a2*b0) (a3*b0)
                                            (a23*b0) (a31*b0) (a12*b0)
  (ODD a1 a2 a3 a123) * (R b0) = ODD (a1*b0) (a2*b0) (a3*b0)
                                     (a123*b0)
  (TPV a23 a31 a12 a123) * (R b0) = TPV (a23*b0) (a31*b0) (a12*b0)
                                        (a123*b0)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (R b0) = APS (a0*b0)
                                                    (a1*b0) (a2*b0) (a3*b0)
                                                    (a23*b0) (a31*b0) (a12*b0)
                                                    (a123*b0)

  (V3 a1 a2 a3) * (V3 b1 b2 b3) = H (a1*b1 + a2*b2 + a3*b3)
                                    (a2*b3 - a3*b2) (a3*b1 - a1*b3) (a1*b2 - a2*b1)

  (V3 a1 a2 a3) * (BV b23 b31 b12) = ODD (a3*b31 - a2*b12) (a1*b12 - a3*b23) (a2*b23 - a1*b31)
                                         (a1*b23 + a2*b31 + a3*b12)
  (V3 a1 a2 a3) * (I b123) = BV (a1*b123) (a2*b123) (a3*b123)
  (V3 a1 a2 a3) * (PV b0 b1 b2 b3) = APS (a1*b1 + a2*b2 + a3*b3)
                                         (a1*b0) (a2*b0) (a3*b0)
                                         (a2*b3 - a3*b2) (a3*b1 - a1*b3) (a1*b2 - a2*b1)
                                         0
  (V3 a1 a2 a3) * (H b0 b23 b31 b12) = ODD (a1*b0 - a2*b12 + a3*b31) (a2*b0 + a1*b12 - a3*b23) (a3*b0 - a1*b31 + a2*b23)
                                           (a1*b23 + a2*b31 + a3*b12)
  (V3 a1 a2 a3) * (C b0 b123) = BPV (a1*b0) (a2*b0) (a3*b0)
                                    (a1*b123) (a2*b123) (a3*b123)
  (V3 a1 a2 a3) * (BPV b1 b2 b3 b23 b31 b12) = APS (a1*b1 + a2*b2 + a3*b3)
                                                   (a3*b31 - a2*b12) (a1*b12 - a3*b23) (a2*b23 - a1*b31)
                                                   (a2*b3 - a3*b2) (a3*b1 - a1*b3) (a1*b2 - a2*b1)
                                                   (a1*b23 + a2*b31 + a3*b12)
  (V3 a1 a2 a3) * (ODD b1 b2 b3 b123) = H (a1*b1 + a2*b2 + a3*b3)
                                          (a1*b123 + a2*b3 - a3*b2) (a2*b123 - a1*b3 + a3*b1) (a3*b123 + a1*b2 - a2*b1)
  (V3 a1 a2 a3) * (TPV b23 b31 b12 b123) = APS 0
                                               (a3*b31 - a2*b12) (a1*b12 - a3*b23) (a2*b23 - a1*b31)
                                               (a1*b123) (a2*b123) (a3*b123)
                                               (a1*b23 + a2*b31 + a3*b12)
  (V3 a1 a2 a3) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a1*b1 + a2*b2 + a3*b3)
                                                           (a1*b0 - a2*b12 + a3*b31) (a2*b0 + a1*b12 - a3*b23) (a3*b0 - a1*b31 + a2*b23)
                                                           (a1*b123 + a2*b3 - a3*b2) (a3*b1 - a1*b3 + a2*b123) (a1*b2 - a2*b1 + a3*b123)
                                                           (a1*b23 + a2*b31 + a3*b12)

  (BV a23 a31 a12) * (V3 b1 b2 b3) = ODD (a12*b2  - a31*b3) (a23*b3 - a12*b1) (a31*b1  - a23*b2)
                                         (a23*b1  + a31*b2  + a12*b3)
  (I a123) * (V3 b1 b2 b3) = BV (a123*b1) (a123*b2) (a123*b3)
  (PV a0 a1 a2 a3) * (V3 b1 b2 b3) = APS (a1*b1 + a2*b2 + a3*b3)
                                         (a0*b1) (a0*b2) (a0*b3)
                                         (a2*b3 - a3*b2) (a3*b1 - a1*b3) (a1*b2 - a2*b1)
                                         0
  (H a0 a23 a31 a12) * (V3 b1 b2 b3) = ODD (a0*b1 + a12*b2 - a31*b3) (a0*b2 - a12*b1 + a23*b3) (a0*b3 + a31*b1 - a23*b2)
                                           (a23*b1 + a31*b2 + a12*b3)
  (C a0 a123) * (V3 b1 b2 b3) = BPV (a0*b1) (a0*b2) (a0*b3)
                                    (a123*b1) (a123*b2) (a123*b3)
  (BPV a1 a2 a3 a23 a31 a12) * (V3 b1 b2 b3) = APS (a1*b1 + a2*b2 + a3*b3)
                                                   (a12*b2 - a31*b3) (a23*b3 - a12*b1) (a31*b1 - a23*b2)
                                                   (a2*b3 - a3*b2) (a3*b1 - a1*b3) (a1*b2 - a2*b1)
                                                   (a23*b1 + a31*b2 + a12*b3)
  (ODD a1 a2 a3 a123) * (V3 b1 b2 b3) = H (a1*b1 + a2*b2 + a3*b3)
                                          (a123*b1 + a2*b3 - a3*b2) (a123*b2 - a1*b3 + a3*b1) (a123*b3 + a1*b2 - a2*b1)
  (TPV a23 a31 a12 a123) * (V3 b1 b2 b3) = APS 0
                                               (a12*b2 - a31*b3) (a23*b3 - a12*b1) (a31*b1 - a23*b2)
                                               (a123*b1) (a123*b2) (a123*b3)
                                               (a23*b1 + a31*b2 + a12*b3)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (V3 b1 b2 b3) = APS (a1*b1 + a2*b2 + a3*b3)
                                                           (a0*b1 + a12*b2 - a31*b3) (a0*b2 - a12*b1 + a23*b3) (a0*b3 + a31*b1 - a23*b2)
                                                           (a123*b1 + a2*b3 - a3*b2) (a3*b1 - a1*b3 + a123*b2) (a1*b2 - a2*b1 + a123*b3)
                                                           (a23*b1 + a31*b2 + a12*b3)

  (BV a23 a31 a12) * (BV b23 b31 b12) = H (negate $ a23*b23 + a31*b31 + a12*b12)
                                          (a12*b31 - a31*b12) (a23*b12 - a12*b23) (a31*b23 - a23*b31)

  (BV a23 a31 a12) * (I b123) = V3 (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
  (BV a23 a31 a12) * (PV b0 b1 b2 b3) = APS 0
                                            (a12*b2 - a31*b3) (a23*b3 - a12*b1) (a31*b1 - a23*b2)
                                            (a23*b0) (a31*b0) (a12*b0)
                                            (a23*b1 + a31*b2 + a12*b3)
  (BV a23 a31 a12) * (H b0 b23 b31 b12) = H (negate $ a23*b23 + a31*b31 + a12*b12)
                                            (a23*b0 - a31*b12 + a12*b31) (a31*b0 + a23*b12 - a12*b23) (a12*b0 - a23*b31 + a31*b23)
  (BV a23 a31 a12) * (C b0 b123) = BPV (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                       (a23*b0) (a31*b0) (a12*b0)
  (BV a23 a31 a12) * (BPV b1 b2 b3 b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                      (a12*b2 - a31*b3) (a23*b3 - a12*b1) (a31*b1 - a23*b2)  
                                                      (a12*b31 - a31*b12) (a23*b12 - a12*b23) (a31*b23 - a23*b31)
                                                      (a23*b1 + a31*b2 + a12*b3)
  (BV a23 a31 a12) * (ODD b1 b2 b3 b123) = ODD (a12*b2 - a31*b3 - a23*b123) (a23*b3 - a12*b1 - a31*b123) (a31*b1 - a23*b2 - a12*b123)
                                               (a23*b1 + a31*b2 + a12*b3)
  (BV a23 a31 a12) * (TPV b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                  (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                                  (a12*b31 - a31*b12) (a23*b12 - a12*b23) (a31*b23 - a23*b31)
                                                  0
  (BV a23 a31 a12) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                              (a12*b2 - a31*b3 - a23*b123) (a23*b3 - a31*b123 - a12*b1) (a31*b1 - a23*b2 - a12*b123)
                                                              (a23*b0 - a31*b12 + a12*b31) (a31*b0 + a23*b12 - a12*b23) (a12*b0 - a23*b31 + a31*b23)
                                                              (a23*b1 + a31*b2 + a12*b3)

  (I a123) * (BV b23 b31 b12) = V3 (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
  (PV a0 a1 a2 a3) * (BV b23 b31 b12) = APS 0
                                            (a3*b31 - a2*b12) (a1*b12 - a3*b23) (a2*b23 - a1*b31)
                                            (a0*b23) (a0*b31) (a0*b12)
                                            (a1*b23 + a2*b31 + a3*b12)
  (H a0 a23 a31 a12) * (BV b23 b31 b12) = H (negate $ a23*b23 + a31*b31 + a12*b12)
                                            (a0*b23 - a31*b12 + a12*b31) (a0*b31 + a23*b12 - a12*b23) (a0*b12 - a23*b31 + a31*b23)
  (C a0 a123) * (BV b23 b31 b12) = BPV (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                       (a0*b23) (a0*b31) (a0*b12)
  (BPV a1 a2 a3 a23 a31 a12) * (BV b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                      (a3*b31 - a2*b12) (a1*b12 - a3*b23) (a2*b23 - a1*b31)    
                                                      (a12*b31 - a31*b12) (a23*b12 - a12*b23) (a31*b23 - a23*b31)
                                                      (a1*b23 + a2*b31 + a3*b12)
  (ODD a1 a2 a3 a123) * (BV b23 b31 b12) = ODD (negate $ a123*b23 + a2*b12 - a3*b31)
                                               (negate $ a123*b31 - a1*b12 + a3*b23)
                                               (negate $ a123*b12 + a1*b31 - a2*b23)
                                               (a1*b23 + a2*b31 + a3*b12)
  (TPV a23 a31 a12 a123) * (BV b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                  (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                                  (negate $ a31*b12 - a12*b31) (negate $ a12*b23 - a23*b12) (negate $ a23*b31 - a31*b23)
                                                  0
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (BV b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)  
                                                              (a3*b31 - a123*b23 - a2*b12) (a1*b12 - a3*b23 - a123*b31) (a2*b23 - a123*b12 - a1*b31)
                                                              (a0*b23 - a31*b12 + a12*b31) (a0*b31 + a23*b12 - a12*b23) (a0*b12 - a23*b31 + a31*b23)
                                                              (a1*b23 + a2*b31 + a3*b12)

  (I a123) * (I b123) = R (negate $ a123*b123)

  (I a123) * (PV b0 b1 b2 b3) = TPV (a123*b1) (a123*b2) (a123*b3)
                                    (a123*b0)
  (I a123) * (H b0 b23 b31 b12) = ODD (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                      (a123*b0)
  (I a123) * (C b0 b123) = C (negate $ a123*b123)
                             (a123*b0)
  (I a123) * (BPV b1 b2 b3 b23 b31 b12) = BPV (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                              (a123*b1) (a123*b2) (a123*b3)
  (I a123) * (ODD b1 b2 b3 b123) = H (negate $ a123*b123)
                                     (a123*b1) (a123*b2) (a123*b3)
  (I a123) * (TPV b23 b31 b12 b123) = PV (negate $ a123*b123)
                                         (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
  (I a123) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (negate $ a123*b123)
                                                      (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                                      (a123*b1) (a123*b2) (a123*b3)
                                                      (a123*b0)

  (PV a0 a1 a2 a3) * (I b123) = TPV (a1*b123) (a2*b123) (a3*b123)
                                    (a0*b123)
  (H a0 a23 a31 a12) * (I b123) = ODD (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                      (a0*b123)
  (C a0 a123) * (I b123) = C (negate $ a123*b123)
                             (a0*b123)
  (BPV a1 a2 a3 a23 a31 a12) * (I b123) = BPV (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                              (a1*b123) (a2*b123) (a3*b123)
  (ODD a1 a2 a3 a123) * (I b123) = H (negate $ a123*b123)
                                     (a1*b123) (a2*b123) (a3*b123)
  (TPV a23 a31 a12 a123) * (I b123) = PV (negate $ a123*b123)
                                         (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (I b123) = APS (negate $ a123*b123)
                                                      (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                                      (a1*b123) (a2*b123) (a3*b123)
                                                      (a0*b123)


  (PV a0 a1 a2 a3) * (PV b0 b1 b2 b3) = APS (a0*b0 + a1*b1 + a2*b2 + a3*b3)
                                            (a0*b1 + a1*b0) (a0*b2 + a2*b0) (a0*b3 + a3*b0)
                                            (a2*b3 - a3*b2) (a3*b1 - a1*b3) (a1*b2 - a2*b1)
                                            0

  (PV a0 a1 a2 a3) * (H b0 b23 b31 b12) = APS (a0*b0)
                                              (a1*b0 - a2*b12 + a3*b31) (a2*b0 + a1*b12 - a3*b23) (a3*b0 - a1*b31 + a2*b23)
                                              (a0*b23) (a0*b31) (a0*b12)
                                              (a1*b23 + a2*b31 + a3*b12)
  (PV a0 a1 a2 a3) * (C b0 b123) = APS (a0*b0)
                                       (a1*b0) (a2*b0) (a3*b0)
                                       (a1*b123) (a2*b123) (a3*b123)
                                       (a0*b123)
  (PV a0 a1 a2 a3) * (BPV b1 b2 b3 b23 b31 b12) = APS (a1*b1 + a2*b2 + a3*b3)
                                                      (a0*b1 - a2*b12 + a3*b31) (a0*b2 + a1*b12 - a3*b23) (a0*b3 - a1*b31 + a2*b23)
                                                      (a0*b23 + a2*b3 - a3*b2) (a0*b31 - a1*b3 + a3*b1) (a0*b12 + a1*b2 - a2*b1)
                                                      (a1*b23 + a2*b31 + a3*b12)
  (PV a0 a1 a2 a3) * (ODD b1 b2 b3 b123) = APS (a1*b1 + a2*b2 + a3*b3)
                                               (a0*b1) (a0*b2) (a0*b3)
                                               (a1*b123 + a2*b3 - a3*b2) (a2*b123 - a1*b3 + a3*b1) (a3*b123 + a1*b2 - a2*b1)
                                               (a0*b123)
  (PV a0 a1 a2 a3) * (TPV b23 b31 b12 b123) = APS 0
                                                  (a3*b31 - a2*b12) (a1*b12 - a3*b23) (a2*b23 - a1*b31)
                                                  (a0*b23 + a1*b123) (a0*b31 + a2*b123) (a0*b12 + a3*b123)
                                                  (a0*b123 + a1*b23 + a2*b31 + a3*b12)
  (PV a0 a1 a2 a3) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0*b0 + a1*b1 + a2*b2 + a3*b3)
                                                              (a0*b1 + a1*b0 - a2*b12 + a3*b31)
                                                              (a0*b2 + a2*b0 + a1*b12 - a3*b23)
                                                              (a0*b3 + a3*b0 - a1*b31 + a2*b23)
                                                              (a0*b23 + a1*b123 + a2*b3 - a3*b2)
                                                              (a0*b31 - a1*b3 + a3*b1 + a2*b123)
                                                              (a0*b12 + a1*b2 - a2*b1 + a3*b123)
                                                              (a0*b123 + a1*b23 + a2*b31 + a3*b12)

  (H a0 a23 a31 a12) * (PV b0 b1 b2 b3) = APS (a0*b0)
                                              (a0*b1 + a12*b2 - a31*b3) (a0*b2 - a12*b1 + a23*b3) (a0*b3 + a31*b1 - a23*b2)
                                              (a23*b0) (a31*b0) (a12*b0)
                                              (a23*b1 + a31*b2 + a12*b3)
  (C a0 a123) * (PV b0 b1 b2 b3) = APS (a0*b0)
                                       (a0*b1) (a0*b2) (a0*b3)
                                       (a123*b1) (a123*b2) (a123*b3)
                                       (a123*b0)
  (BPV a1 a2 a3 a23 a31 a12) * (PV b0 b1 b2 b3) = APS (a1*b1 + a2*b2 + a3*b3)
                                                      (a1*b0 + a12*b2 - a31*b3) (a2*b0 - a12*b1 + a23*b3) (a3*b0 + a31*b1 - a23*b2)
                                                      (a23*b0 + a2*b3 - a3*b2) (a31*b0 - a1*b3 + a3*b1) (a12*b0 + a1*b2 - a2*b1)
                                                      (a23*b1 + a31*b2 + a12*b3)
  (ODD a1 a2 a3 a123) * (PV b0 b1 b2 b3) = APS (a1*b1 + a2*b2 + a3*b3)
                                               (a1*b0) (a2*b0) (a3*b0)
                                               (a123*b1 + a2*b3 - a3*b2)
                                               (a123*b2 - a1*b3 + a3*b1)
                                               (a123*b3 + a1*b2 - a2*b1)
                                               (a123*b0)
  (TPV a23 a31 a12 a123) * (PV b0 b1 b2 b3) = APS 0
                                                  (a12*b2 - a31*b3) (a23*b3 - a12*b1) (a31*b1 - a23*b2)
                                                  (a23*b0 + a123*b1) (a31*b0 + a123*b2) (a12*b0 + a123*b3)
                                                  (a123*b0 + a23*b1 + a31*b2 + a12*b3)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (PV b0 b1 b2 b3) = APS (a0*b0 + a1*b1 + a2*b2 + a3*b3)
                                                              (a0*b1 + a1*b0 + a12*b2 - a31*b3)
                                                              (a0*b2 + a2*b0 - a12*b1 + a23*b3)
                                                              (a0*b3 + a3*b0 + a31*b1 - a23*b2)
                                                              (a23*b0 + a123*b1 + a2*b3 - a3*b2)
                                                              (a31*b0 - a1*b3 + a3*b1 + a123*b2)
                                                              (a12*b0 + a1*b2 - a2*b1 + a123*b3)
                                                              (a123*b0 + a23*b1 + a31*b2 + a12*b3)

  (H a0 a23 a31 a12) * (H b0 b23 b31 b12) = H (a0*b0 - a23*b23 - a31*b31 - a12*b12)
                                              (a0*b23 + a23*b0 - a31*b12 + a12*b31)
                                              (a0*b31 + a31*b0 + a23*b12 - a12*b23)
                                              (a0*b12 + a12*b0 - a23*b31 + a31*b23)

  (H a0 a23 a31 a12) * (C b0 b123) = APS (a0*b0)
                                         (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                         (a23*b0) (a31*b0) (a12*b0)
                                         (a0*b123)
  (H a0 a23 a31 a12) * (BPV b1 b2 b3 b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                        (a0*b1 + a12*b2 - a31*b3) (a0*b2 - a12*b1 + a23*b3) (a0*b3 + a31*b1 - a23*b2)
                                                        (a0*b23 - a31*b12 + a12*b31) (a0*b31 + a23*b12 - a12*b23) (a0*b12 - a23*b31 + a31*b23)
                                                        (a23*b1 + a31*b2  + a12*b3)
  (H a0 a23 a31 a12) * (ODD b1 b2 b3 b123) = ODD (a0*b1 + a12*b2 - a31*b3 - a23*b123)
                                                 (a0*b2 - a12*b1 + a23*b3 - a31*b123)
                                                 (a0*b3 + a31*b1 - a23*b2 - a12*b123)
                                                 (a0*b123 + a23*b1 + a31*b2 + a12*b3)
  (H a0 a23 a31 a12) * (TPV b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                    (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                                    (a0*b23 - a31*b12 + a12*b31) (a0*b31 + a23*b12 - a12*b23) (a0*b12 - a23*b31 + a31*b23)
                                                    (a0*b123)
  (H a0 a23 a31 a12) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0*b0 - a23*b23 - a31*b31 - a12*b12)
                                                                (a0*b1 + a12*b2 - a31*b3 - a23*b123)
                                                                (a0*b2 - a12*b1 + a23*b3 - a31*b123)
                                                                (a0*b3 + a31*b1 - a23*b2 - a12*b123)
                                                                (a0*b23 + a23*b0 - a31*b12 + a12*b31)
                                                                (a0*b31 + a31*b0 + a23*b12 - a12*b23)
                                                                (a0*b12 + a12*b0 - a23*b31 + a31*b23)
                                                                (a0*b123 + a23*b1 + a31*b2 + a12*b3)

  (C a0 a123) * (H b0 b23 b31 b12) = APS (a0*b0)
                                         (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                         (a0*b23) (a0*b31) (a0*b12)
                                         (a123*b0)
  (BPV a1 a2 a3 a23 a31 a12) * (H b0 b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                        (a1*b0 - a2*b12 + a3*b31) (a2*b0 + a1*b12 - a3*b23) (a3*b0 - a1*b31 + a2*b23)
                                                        (a23*b0 - a31*b12 + a12*b31) (a31*b0 + a23*b12 - a12*b23) (a12*b0 - a23*b31 + a31*b23)
                                                        (a1*b23 + a2*b31 + a3*b12)
  (ODD a1 a2 a3 a123) * (H b0 b23 b31 b12) = ODD (a1*b0 - a2*b12 + a3*b31 - a123*b23)
                                                 (a2*b0 + a1*b12 - a3*b23 - a123*b31)
                                                 (a3*b0 - a1*b31 + a2*b23 - a123*b12)
                                                 (a123*b0 + a1*b23 + a2*b31 + a3*b12)
  (TPV a23 a31 a12 a123) * (H b0 b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                    (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                                    (a23*b0 - a31*b12 + a12*b31) (a31*b0 + a23*b12 - a12*b23) (a12*b0 - a23*b31 + a31*b23)
                                                    (a123*b0)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (H b0 b23 b31 b12) = APS (a0*b0 - a23*b23 - a31*b31 - a12*b12)
                                                                (a1*b0 - a2*b12 + a3*b31 - a123*b23)
                                                                (a2*b0 + a1*b12 - a3*b23 - a123*b31)
                                                                (a3*b0 - a1*b31 + a2*b23 - a123*b12)
                                                                (a0*b23 + a23*b0 - a31*b12 + a12*b31)
                                                                (a0*b31 + a31*b0 + a23*b12 - a12*b23)
                                                                (a0*b12 + a12*b0 - a23*b31 + a31*b23)
                                                                (a123*b0 + a1*b23 + a2*b31 + a3*b12)

  (C a0 a123) * (C b0 b123) = C (a0*b0 - a123*b123)
                                (a0*b123 + a123*b0)

  (C a0 a123) * (BPV b1 b2 b3 b23 b31 b12) = BPV (a0*b1 - a123*b23) (a0*b2 - a123*b31) (a0*b3 - a123*b12)
                                                 (a0*b23 + a123*b1) (a0*b31 + a123*b2) (a0*b12 + a123*b3)
  (C a0 a123) * (ODD b1 b2 b3 b123) = APS (negate $ a123*b123)
                                          (a0*b1) (a0*b2) (a0*b3)
                                          (a123*b1) (a123*b2) (a123*b3)
                                          (a0*b123)
  (C a0 a123) * (TPV b23 b31 b12 b123) = APS (negate $ a123*b123)
                                             (negate $ a123*b23) (negate $ a123*b31) (negate $ a123*b12)
                                             (a0*b23) (a0*b31) (a0*b12)
                                             (a0*b123)
  (C a0 a123) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0*b0 - a123*b123)
                                                         (a0*b1 - a123*b23) (a0*b2 - a123*b31) (a0*b3 - a123*b12)
                                                         (a0*b23 + a123*b1) (a0*b31 + a123*b2) (a0*b12 + a123*b3)
                                                         (a0*b123 + a123*b0)

  (BPV a1 a2 a3 a23 a31 a12) * (C b0 b123) = BPV (a1*b0 - a23*b123) (a2*b0 - a31*b123) (a3*b0 - a12*b123)
                                                 (a23*b0 + a1*b123) (a31*b0 + a2*b123) (a12*b0 + a3*b123)
  (ODD a1 a2 a3 a123) * (C b0 b123) = APS (negate $ a123*b123)
                                          (a1*b0) (a2*b0) (a3*b0)
                                          (a1*b123) (a2*b123) (a3*b123)
                                          (a123*b0)
  (TPV a23 a31 a12 a123) * (C b0 b123) = APS (negate $ a123*b123)
                                             (negate $ a23*b123) (negate $ a31*b123) (negate $ a12*b123)
                                             (a23*b0) (a31*b0) (a12*b0)
                                             (a123*b0)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (C b0 b123) = APS (a0*b0 - a123*b123)
                                                         (a1*b0 - a23*b123) (a2*b0 - a31*b123) (a3*b0 - a12*b123)
                                                         (a23*b0 + a1*b123) (a31*b0 + a2*b123) (a12*b0 + a3*b123)
                                                         (a0*b123 + a123*b0)

  (BPV a1 a2 a3 a23 a31 a12) * (BPV b1 b2 b3 b23 b31 b12) = APS (a1*b1 + a2*b2 + a3*b3 - a23*b23 - a31*b31 - a12*b12)
                                                                (a12*b2 - a2*b12 + a3*b31 - a31*b3)
                                                                (a1*b12 - a12*b1 - a3*b23 + a23*b3)
                                                                (a31*b1 - a1*b31 + a2*b23 - a23*b2)
                                                                (a2*b3 - a3*b2 - a31*b12 + a12*b31)
                                                                (a3*b1 - a1*b3 + a23*b12 - a12*b23)
                                                                (a1*b2 - a2*b1 - a23*b31 + a31*b23)
                                                                (a1*b23 + a23*b1 + a2*b31 + a31*b2 + a3*b12 + a12*b3)

  (BPV a1 a2 a3 a23 a31 a12) * (ODD b1 b2 b3 b123) = APS (a1*b1 + a2*b2 + a3*b3)
                                                         (a12*b2 - a31*b3 - a23*b123) (a23*b3 - a12*b1 - a31*b123) (a31*b1 - a23*b2 - a12*b123)
                                                         (a1*b123 + a2*b3 - a3*b2) (a2*b123 - a1*b3 + a3*b1) (a3*b123 + a1*b2 - a2*b1)
                                                         (a23*b1 + a31*b2 + a12*b3)
  (BPV a1 a2 a3 a23 a31 a12) * (TPV b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                            (a3*b31 - a2*b12 - a23*b123) (a1*b12 - a3*b23 - a31*b123) (a2*b23 - a1*b31 - a12*b123)
                                                            (a1*b123 - a31*b12 + a12*b31) (a2*b123 + a23*b12 - a12*b23) (a3*b123 - a23*b31 + a31*b23)
                                                            (a1*b23 + a2*b31 + a3*b12)
  (BPV a1 a2 a3 a23 a31 a12) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a1*b1 + a2*b2 + a3*b3 - a23*b23 - a31*b31 - a12*b12)
                                                                        (a1*b0 - a2*b12 + a12*b2 + a3*b31 - a31*b3 - a23*b123)
                                                                        (a2*b0 + a1*b12 - a12*b1 - a3*b23 + a23*b3 - a31*b123)
                                                                        (a3*b0 - a1*b31 + a31*b1 + a2*b23 - a23*b2 - a12*b123)
                                                                        (a23*b0 + a1*b123 + a2*b3 - a3*b2 - a31*b12 + a12*b31)
                                                                        (a31*b0 - a1*b3 + a3*b1 + a2*b123 + a23*b12 - a12*b23)
                                                                        (a12*b0 + a1*b2 - a2*b1 + a3*b123 - a23*b31 + a31*b23)
                                                                        (a1*b23 + a23*b1 + a2*b31 + a31*b2 + a3*b12 + a12*b3)

  (ODD a1 a2 a3 a123) * (BPV b1 b2 b3 b23 b31 b12) = APS (a1*b1 + a2*b2 + a3*b3)
                                                         (a3*b31 - a2*b12 - a123*b23) (a1*b12 - a3*b23 - a123*b31) (a2*b23 - a1*b31 - a123*b12)
                                                         (a123*b1 + a2*b3 - a3*b2) (a123*b2 - a1*b3 + a3*b1) (a123*b3 + a1*b2 - a2*b1)
                                                         (a1*b23 + a2*b31 + a3*b12)
  (TPV a23 a31 a12 a123) * (BPV b1 b2 b3 b23 b31 b12) = APS (negate $ a23*b23 + a31*b31 + a12*b12)
                                                            (a12*b2 - a31*b3 - a123*b23) (a23*b3 - a12*b1 - a123*b31) (a31*b1 - a23*b2 - a123*b12)
                                                            (a123*b1 - a31*b12 + a12*b31) (a123*b2 + a23*b12 - a12*b23) (a123*b3 - a23*b31 + a31*b23)
                                                            (a23*b1 + a31*b2 + a12*b3)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (BPV b1 b2 b3 b23 b31 b12) = APS (a1*b1 + a2*b2 + a3*b3 - a23*b23 - a31*b31 - a12*b12)
                                                                        (a0*b1 - a2*b12 + a12*b2 + a3*b31 - a31*b3 - a123*b23)
                                                                        (a0*b2 + a1*b12 - a12*b1 - a3*b23 + a23*b3 - a123*b31)
                                                                        (a0*b3 - a1*b31 + a31*b1 + a2*b23 - a23*b2 - a123*b12)
                                                                        (a0*b23 + a123*b1 + a2*b3 - a3*b2 - a31*b12 + a12*b31)
                                                                        (a0*b31 - a1*b3 + a3*b1 + a123*b2 + a23*b12 - a12*b23)
                                                                        (a0*b12 + a1*b2 - a2*b1 + a123*b3 - a23*b31 + a31*b23)
                                                                        (a1*b23 + a23*b1 + a2*b31 + a31*b2 + a3*b12 + a12*b3)

  (ODD a1 a2 a3 a123) * (ODD b1 b2 b3 b123) = H (a1*b1 + a2*b2 + a3*b3 - a123*b123)
                                                (a1*b123 + a123*b1 + a2*b3 - a3*b2)
                                                (a2*b123 + a123*b2 - a1*b3 + a3*b1)
                                                (a3*b123 + a123*b3 + a1*b2 - a2*b1)

  (ODD a1 a2 a3 a123) * (TPV b23 b31 b12 b123) = APS (negate $ a123*b123)
                                                     (a3*b31 - a2*b12 - a123*b23) (a1*b12 - a3*b23 - a123*b31) (a2*b23 - a1*b31 - a123*b12)
                                                     (a1*b123) (a2*b123) (a3*b123)
                                                     (a1*b23 + a2*b31 + a3*b12)
  (ODD a1 a2 a3 a123) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a1*b1 + a2*b2 + a3*b3 - a123*b123)
                                                                 (a1*b0 - a2*b12 + a3*b31 - a123*b23)
                                                                 (a2*b0 + a1*b12 - a3*b23 - a123*b31)
                                                                 (a3*b0 - a1*b31 + a2*b23 - a123*b12)
                                                                 (a1*b123 + a123*b1 + a2*b3 - a3*b2)
                                                                 (a2*b123 + a123*b2 - a1*b3 + a3*b1)
                                                                 (a3*b123 + a123*b3 + a1*b2 - a2*b1)
                                                                 (a123*b0 + a1*b23 + a2*b31 + a3*b12)

  (TPV a23 a31 a12 a123) * (ODD b1 b2 b3 b123) = APS (negate $ a123*b123)
                                                     (a12*b2 - a31*b3 - a23*b123) (a23*b3 - a12*b1 - a31*b123) (a31*b1 - a23*b2 - a12*b123)
                                                     (a123*b1) (a123*b2) (a123*b3)
                                                     (a23*b1 + a31*b2 + a12*b3)
  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (ODD b1 b2 b3 b123) = APS (a1*b1 + a2*b2 + a3*b3 - a123*b123)
                                                                 (a0*b1 + a12*b2 - a31*b3 - a23*b123)
                                                                 (a0*b2 - a12*b1 + a23*b3 - a31*b123)
                                                                 (a0*b3 + a31*b1 - a23*b2 - a12*b123)
                                                                 (a1*b123 + a123*b1 + a2*b3 - a3*b2)
                                                                 (a2*b123 + a123*b2 - a1*b3 + a3*b1)
                                                                 (a3*b123 + a123*b3 + a1*b2 - a2*b1)
                                                                 (a0*b123 + a23*b1 + a31*b2 + a12*b3)

  (TPV a23 a31 a12 a123) * (TPV b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12 + a123*b123)
                                                        (negate $ a23*b123 + a123*b23) (negate $ a31*b123 + a123*b31) (negate $ a12*b123 + a123*b12)
                                                        (a12*b31 - a31*b12) (a23*b12 - a12*b23) (a31*b23 - a23*b31)
                                                        0

  (TPV a23 a31 a12 a123) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12 + a123*b123)
                                                                    (a12*b2 - a31*b3 - a23*b123 - a123*b23)
                                                                    (a23*b3 - a12*b1 - a31*b123 - a123*b31)
                                                                    (a31*b1 - a23*b2 - a12*b123 - a123*b12)
                                                                    (a23*b0 + a123*b1 - a31*b12 + a12*b31)
                                                                    (a31*b0 + a123*b2 + a23*b12 - a12*b23)
                                                                    (a12*b0 + a123*b3 - a23*b31 + a31*b23)
                                                                    (a123*b0 + a23*b1 + a31*b2 + a12*b3)

  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (TPV b23 b31 b12 b123) = APS (negate $ a23*b23 + a31*b31 + a12*b12 + a123*b123)
                                                                    (a3*b31 - a2*b12 - a23*b123 - a123*b23)
                                                                    (a1*b12 - a3*b23 - a31*b123 - a123*b31)
                                                                    (a2*b23 - a1*b31 - a12*b123 - a123*b12)
                                                                    (a0*b23 + a1*b123 - a31*b12 + a12*b31)
                                                                    (a0*b31 + a2*b123 + a23*b12 - a12*b23)
                                                                    (a0*b12 + a3*b123 - a23*b31 + a31*b23)
                                                                    (a0*b123 + a1*b23 + a2*b31 + a3*b12)

  (APS a0 a1 a2 a3 a23 a31 a12 a123) * (APS b0 b1 b2 b3 b23 b31 b12 b123) = APS (a0*b0 + a1*b1 + a2*b2 + a3*b3 - a23*b23 - a31*b31 - a12*b12 - a123*b123)
                                                                                (a0*b1 + a1*b0 - a2*b12 + a12*b2 + a3*b31 - a31*b3 - a23*b123 - a123*b23)
                                                                                (a0*b2 + a2*b0 + a1*b12 - a12*b1 - a3*b23 + a23*b3 - a31*b123 - a123*b31)
                                                                                (a0*b3 + a3*b0 - a1*b31 + a31*b1 + a2*b23 - a23*b2 - a12*b123 - a123*b12)
                                                                                (a0*b23 + a23*b0 + a1*b123 + a123*b1 + a2*b3 - a3*b2 - a31*b12 + a12*b31)
                                                                                (a0*b31 + a31*b0 - a1*b3 + a3*b1 + a2*b123 + a123*b2 + a23*b12 - a12*b23)
                                                                                (a0*b12 + a12*b0 + a1*b2 - a2*b1 + a3*b123 + a123*b3 - a23*b31 + a31*b23)
                                                                                (a0*b123 + a123*b0 + a1*b23 + a23*b1 + a2*b31 + a31*b2 + a3*b12 + a12*b3)


  -- |'abs' is the spectral norm aka the spectral radius
  -- it is the largest singular value. This function may need to be fiddled with
  -- to make the math a bit safer wrt overflows.  This makes use of the largest
  -- singular value, if the smallest singular value is zero then the element is not
  -- invertable, we can see here that R, C, V3, BV, and H are all invertable.
  abs (R a0) = R (abs a0) -- absolute value of a real number
  abs (V3 a1 a2 a3) = R (sqrt (a1^2 + a2^2 + a3^2)) -- magnitude of a vector
  abs (BV a23 a31 a12) = R (sqrt (a23^2 + a31^2 + a12^2)) -- magnitude of a bivector
  abs (I a123) = R (abs a123) -- magnitude of a Imaginary number
  abs (PV a0 a1 a2 a3) = R (sqrt (a0^2 + a1^2 + a2^2 + a3^2 + 2 * abs a0 * sqrt (a1^2 + a2^2 + a3^2)))
  abs (H a0 a23 a31 a12) = R (sqrt (a0^2 + a23^2 + a31^2 + a12^2)) -- largest singular value
  abs (C a0 a123) = R (sqrt (a0^2 + a123^2)) -- magnitude of a complex number
  abs (BPV a1 a2 a3 a23 a31 a12) = R (sqrt (a1^2 + a23^2 + a2^2 + a31^2 + a3^2 + a12^2 +
                                             2 * sqrt ((a1*a31 - a2*a23)^2 + (a1*a12 - a3*a23)^2 + (a2*a12 - a3*a31)^2)))
  abs (ODD a1 a2 a3 a123) = R (sqrt (a1^2 + a2^2 + a3^2 + a123^2))
  abs (TPV a23 a31 a12 a123) = R (sqrt (a23^2 + a31^2 + a12^2 + a123^2 + 2 * abs a123 * sqrt (a23^2 + a31^2 + a12^2)))
  abs (APS a0 a1 a2 a3 a23 a31 a12 a123) = R (sqrt (a0^2 + a1^2 + a2^2 + a3^2 + a23^2 + a31^2 + a12^2 + a123^2 +
                                                    2 * sqrt ((a0*a1 + a123*a23)^2 + (a0*a2 + a123*a31)^2 + (a0*a3 + a123*a12)^2 +
                                                              (a2*a12 - a3*a31)^2 + (a3*a23 - a1*a12)^2 + (a1*a31 - a2*a23)^2)))


  -- |'signum' satisfies the Law "abs x * signum x == x"
  -- kind of cool: signum of a vector is the unit vector.
  signum cliffor
    | abs cliffor == 0 = 0  -- initially this was abs cliffor < tol, but this caused problems with 'spectraldcmp'
    | otherwise =
        let (R mag) = abs cliffor
        in cliffor * R (recip mag)


  -- |'fromInteger'
  fromInteger int = R (fromInteger int)


  -- |'negate' simply distributes into the grade components
  negate (R a0) = R (negate a0)
  negate (V3 a1 a2 a3) = V3 (negate a1) (negate a2) (negate a3)
  negate (BV a23 a31 a12) = BV (negate a23) (negate a31) (negate a12)
  negate (I a123) = I (negate a123)
  negate (PV a0 a1 a2 a3) =  PV (negate a0)
                                (negate a1) (negate a2) (negate a3)
  negate (H a0 a23 a31 a12) = H (negate a0)
                                (negate a23) (negate a31) (negate a12)
  negate (C a0 a123) = C (negate a0)
                         (negate a123)
  negate (BPV a1 a2 a3 a23 a31 a12) = BPV (negate a1) (negate a2) (negate a3)
                                          (negate a23) (negate a31) (negate a12)
  negate (ODD a1 a2 a3 a123) = ODD (negate a1) (negate a2) (negate a3)
                                   (negate a123)
  negate (TPV a23 a31 a12 a123) = TPV (negate a23) (negate a31) (negate a12)
                                      (negate a123)
  negate (APS a0 a1 a2 a3 a23 a31 a12 a123) = APS (negate a0)
                                                  (negate a1) (negate a2) (negate a3)
                                                  (negate a23) (negate a31) (negate a12)
                                                  (negate a123)


-- |Cl(3,0) has a Fractional instance
instance Fractional Cl3 where
  -- |Some of the sub algebras are division algebras but APS is not a division algebra
  recip (R a0) = R (recip a0)   -- R is a division algebra
  recip v@(V3 a1 a2 a3) =
    let (R mag) = abs v
        sqmag = mag * mag :: Double
    in V3 (a1 / sqmag) (a2 / sqmag) (a3 / sqmag)
  recip bv@(BV a23 a31 a12) =
    let (R mag) = abs bv
        sqmag = mag * mag  :: Double
    in BV (negate $ a23 / sqmag) (negate $ a31 / sqmag) (negate $ a12 / sqmag)
  recip i@(I a123) =
    let (R mag) = abs i
        sqmag = mag * mag  :: Double
    in I (negate $ a123 / sqmag)
  recip pv@PV{} =
    let mag = toR $ pv * bar pv
    in recip mag * bar pv
  recip h@(H a0 a23 a31 a12) =   -- H is a division algebra
    let (R mag) = abs h
        sqmag = mag * mag  :: Double
    in H (a0 / sqmag) (negate $ a23 / sqmag) (negate $ a31 / sqmag) (negate $ a12 / sqmag)
  recip z@(C a0 a123) =   -- C is a division algebra
    let (R mag) = abs z
        sqmag = mag * mag  :: Double
    in C (a0 / sqmag) (negate $ a123 / sqmag)
  recip bpv@BPV{} = reduce $ spectraldcmp recip recip' bpv
  recip od@(ODD a1 a2 a3 a123) =
    let (R mag) = abs od
        sqmag = mag * mag  :: Double
    in ODD (a1 / sqmag) (a2 / sqmag) (a3 / sqmag) (negate $ a123 / sqmag)
  recip tpv@TPV{} =
    let mag = toR $ tpv * bar tpv
    in recip mag * bar tpv
  recip aps@APS{} = reduce $ spectraldcmp recip recip' aps

  -- |'fromRational'
  fromRational rat = R (fromRational rat)


-- |Cl(3,0) has a "Floating" instance.
instance Floating Cl3 where
  pi = R pi

  --
  exp (R a0) = R (exp a0)
  exp (I a123) = C (cos a123) (sin a123)
  exp (C a0 a123) =
    let expa0 = exp a0
    in C (expa0 * cos a123) (expa0 * sin a123)
  exp cliffor = reduce $ spectraldcmp exp exp' cliffor

  --
  log (R a0) | a0 >= 0 = R (log a0)
             | otherwise = C (log (negate a0)) pi
  log (I a123) = C (log (abs a123)) (signum a123 * (pi/2))
  log (C a0 a123) = C (log (sqrt (a0^2 + a123^2))) (atan2 a123 a0)
  log cliffor = reduce $ spectraldcmp log log' cliffor

  --
  sqrt (R a0) | a0 >= 0 = R (sqrt a0)
              | otherwise = I (sqrt $ negate a0)
  sqrt (I a123) = C u (if a123 < 0 then -v else v)
                       where v = if u < tol' then 0 else abs a123 / (2 * u)
                             u = sqrt (abs a123 / 2)
  sqrt (C a0 a123) = C u (if a123 < 0 then -v else v)
                       where (u,v) = if a0 < 0 then (v',u') else (u',v')
                             v'    = if u' < tol' then  0 else abs a123 / (u'*2)
                             u'    = sqrt ((sqrt (a0^2 + a123^2) + abs a0) / 2)
  sqrt cliffor = reduce $ spectraldcmp sqrt sqrt' cliffor

  --
  sin (R a0) = R (sin a0)
  sin (I a123) = I (sinh a123)
  sin (C a0 a123) = C (sin a0 * cosh a123) (cos a0 * sinh a123)
  sin cliffor = reduce $ spectraldcmp sin sin' cliffor

  --
  cos (R a0) = R (cos a0)
  cos (I a123) = R (cosh a123)
  cos (C a0 a123) = C (cos a0 * cosh a123) (negate $ sin a0 * sinh a123)
  cos cliffor = reduce $ spectraldcmp cos cos' cliffor

  --
  tan (R a0) = R (tan a0)
  tan (I a123) = I (tanh a123)
  tan (C a0 a123) = C (sinx*coshy) (cosx*sinhy) / C (cosx*coshy) (negate $ sinx*sinhy)
                       where sinx  = sin a0
                             cosx  = cos a0
                             sinhy = sinh a123
                             coshy = cosh a123
  tan cliffor = reduce $ spectraldcmp tan tan' cliffor

  --
  asin (R a0) = if (-1) <= a0 && a0 <= 1 then R (asin a0) else asin $ C a0 0
  asin (I a123) = I (asinh a123)
  asin (C a0 a123) = C a123' (-a0')
                       where  (C a0' a123') = toC $ log (C (-a123) a0 + sqrt (1 - C a0 a123 * C a0 a123)) -- check this
  asin cliffor = reduce $ spectraldcmp asin asin' cliffor

  --
  acos (R a0) = if (-1) <= a0 && a0 <= 1 then R (acos a0) else acos $ C a0 0
  acos (I a123) = C (pi/2) (negate $ asinh a123)
  acos (C a0 a123) = C a123'' (-a0'')
               where (C a0'' a123'') = log (C a0 a123 + C (-a123') a0')  -- check this
                     (C a0' a123')   = sqrt (1 - C a0 a123 * C a0 a123)  -- check this
  acos cliffor = reduce $ spectraldcmp acos acos' cliffor

  --  
  atan (R a0) = R (atan a0)
  atan (I a123) = C a123' (-a0')
                       where (C a0' a123') = toC.log $ ( R (1-a123) / sqrt (R (1 - a123^2)))  -- check this
  atan (C a0 a123) = C a123' (-a0')
                       where (C a0' a123') = toC $ log (C (1-a123) a0 / sqrt (1 + C a0 a123 * C a0 a123))  -- check this
  atan cliffor = reduce $ spectraldcmp atan atan' cliffor

  --
  sinh (R a0) = R (sinh a0)
  sinh (I a123) = I (sin a123)
  sinh (C a0 a123) = C (cos a123 * sinh a0) (sin a123 * cosh a0)
  sinh cliffor = reduce $ spectraldcmp sinh sinh' cliffor

  --
  cosh (R a0) = R (cosh a0)
  cosh (I a123) = R (cos a123)
  cosh (C a0 a123) = C (cos a123 * cosh a0) (sin a123 * sinh a0)
  cosh cliffor = reduce $ spectraldcmp cosh cosh' cliffor

  --
  tanh (R a0) = R (tanh a0)
  tanh (I a123) = I (tan a123)
  tanh (C a0 a123) = C (cosy*sinhx) (siny*coshx) / C (cosy*coshx) (siny*sinhx)
                        where siny  = sin a123
                              cosy  = cos a123
                              sinhx = sinh a0
                              coshx = cosh a0
  tanh cliffor = reduce $ spectraldcmp tanh tanh' cliffor

  --
  asinh (R a0) = R (asinh a0)
  asinh (I a123) = log (I a123 + sqrt (R (1 - a123^2)))
  asinh (C a0 a123) = log (C a0 a123 + sqrt (1 + C a0 a123 * C a0 a123))
  asinh cliffor = reduce $ spectraldcmp asinh asinh' cliffor

  --
  acosh (R a0) = log (R a0 + sqrt(R a0 - 1) * sqrt(R a0 + 1))
  acosh (I a123) = log (I a123 + sqrt(I a123 - 1) * sqrt(I a123 + 1))
  acosh (C a0 a123) = log (C a0 a123 + sqrt(C a0 a123 - 1) * sqrt(C a0 a123 + 1))
  acosh cliffor = reduce $ spectraldcmp acosh acosh' cliffor

  --
  atanh (R a0) = 0.5 * log (1 + R a0) - 0.5 * log (1 - R a0)
  atanh (I a123) = 0.5 * log (1 + I a123) - 0.5 * log (1 - I a123)
  atanh (C a0 a123) = 0.5 * log (1 + C a0 a123) - 0.5 * log (1 - C a0 a123)
  atanh cliffor = reduce $ spectraldcmp atanh atanh' cliffor



-- |'lsv' the littlest singular value. Useful for testing for invertability.
lsv :: Cl3 -> Cl3
lsv (R a0) = R (abs a0) -- absolute value of a real number
lsv (V3 a1 a2 a3) = R (sqrt (a1^2 + a2^2 + a3^2)) -- magnitude of a vector
lsv (BV a23 a31 a12) = R (sqrt (a23^2 + a31^2 + a12^2)) -- magnitude of a bivector
lsv (I a123) = R (abs a123)
lsv (PV a0 a1 a2 a3) = R (sqrt (a0^2 + a1^2 + a2^2 + a3^2 -
                                2 * abs a0 * sqrt (a1^2 + a2^2 + a3^2)))
lsv (H a0 a23 a31 a12) = R (sqrt (a0^2 + a23^2 + a31^2 + a12^2))
lsv (C a0 a123) = R (sqrt (a0^2 + a123^2)) -- magnitude of a complex number
lsv (BPV a1 a2 a3 a23 a31 a12) = R (sqrt (a1^2 + a23^2 + a2^2 + a31^2 + a3^2 + a12^2 -
                                          2 * sqrt ((a1*a31 - a2*a23)^2 + (a1*a12 - a3*a23)^2 + (a2*a12 - a3*a31)^2)))
lsv (ODD a1 a2 a3 a123) = R (sqrt (a1^2 + a2^2 + a3^2 + a123^2))
lsv (TPV a23 a31 a12 a123) = R (sqrt (a23^2 + a31^2 + a12^2 + a123^2 - (abs a123 + abs a123) * sqrt (a23^2 + a31^2 + a12^2)))
lsv (APS a0 a1 a2 a3 a23 a31 a12 a123) = R (sqrt (a0^2 + a1^2 + a2^2 + a3^2 + a23^2 + a31^2 + a12^2 + a123^2 -
                                                  2 * sqrt ((a0*a1 + a123*a23)^2 + (a0*a2 + a123*a31)^2 + (a0*a3 + a123*a12)^2 +
                                                            (a2*a12 - a3*a31)^2 + (a3*a23 - a1*a12)^2 + (a1*a31 - a2*a23)^2)))



-- | 'spectraldcmp' the spectral decomposition of a function to calculate analytic functions of cliffors in Cl(3,0).
-- This function requires the desired function to be calculated and it's derivative.
-- If multiple functions are being composed, its best to pass the composition of the funcitons
-- to this function and the derivative to this function.  Any function with a Taylor Series
-- approximation should be able to be used.  A real, imaginary, and complex version of the function to be decomposed
-- must be provided and spectraldcmp will handle the case for an arbitrary Cliffor.
-- 
-- It may be possible to add, in the future, a RULES pragma like:
--
-- > "spectral decomposition function composition"
-- > forall f f' g g' cliff.
-- > spectraldcmp f f' (spectraldcmp g g' cliff) = spectraldcmp (f.g) (f'.g') cliff
-- 
-- 
spectraldcmp :: (Cl3 -> Cl3) -> (Cl3 -> Cl3) -> Cl3 -> Cl3
spectraldcmp fun fun' (reduce -> cliffor) = dcmp cliffor
  where
    dcmp (r@R{}) = fun r
    dcmp (v@V3{}) = spectraldcmpSpecial toR fun v -- spectprojR fun v
    dcmp (bv@BV{}) = spectraldcmpSpecial toI fun bv -- spectprojI fun bv
    dcmp (i@I{}) = fun i
    dcmp (pv@PV{}) = spectraldcmpSpecial toR fun pv -- spectprojR fun pv
    dcmp (h@H{}) = spectraldcmpSpecial toC fun h -- spectprojC fun h
    dcmp (c@C{}) = fun c
    dcmp (bpv@BPV{})
      | hasNilpotent bpv = jordan toR fun fun' bpv  -- jordan normal form Cl3 style
      | isColinear bpv = spectraldcmpSpecial toC fun bpv -- spectprojC fun bpv
      | otherwise =                          -- transform it so it will be colinear
          let (v,d,v_bar) = boost2colinear bpv
          in v * spectraldcmpSpecial toC fun d * v_bar -- v * spectprojC fun d * v_bar
    dcmp (od@ODD{}) = spectraldcmpSpecial toC fun od -- spectprojC fun od
    dcmp (tpv@TPV{}) = spectraldcmpSpecial toI fun tpv -- spectprojI fun tpv
    dcmp (aps@APS{})
      | hasNilpotent aps = jordan toC fun fun' aps  -- jordan normal form Cl3 style
      | isColinear aps = spectraldcmpSpecial toC fun aps -- spectprojC fun aps
      | otherwise =                          -- transform it so it will be colinear
          let (v,d,v_bar) = boost2colinear aps
          in v * spectraldcmpSpecial toC fun d * v_bar -- v * spectprojC fun d * v_bar
--

-- | 'jordan' does a Cl(3,0) version of the decomposition into Jordan Normal Form and Matrix Function Calculation
-- The intended use is for calculating functions for cliffors with vector parts simular to Nilpotent.
-- It is a helper function for 'spectproj'.  It is fortunate because eigen decomposition doesn't
-- work with elements with nilpotent content, so it fills the gap.
jordan :: (Cl3 -> Cl3) -> (Cl3 -> Cl3) -> (Cl3 -> Cl3) -> Cl3 -> Cl3
jordan toSpecial fun fun' cliffor =
  let eigs = toSpecial cliffor
  in fun eigs + fun' eigs * toBPV cliffor

-- | 'spectraldcmpSpecial' helper function for with specialization for real, imaginary, or complex eigenvalues.
-- To specialize for Reals pass 'toR', to specialize for Imaginary pass 'toI', to specialize for Complex pass 'toC'
spectraldcmpSpecial :: (Cl3 -> Cl3) -> (Cl3 -> Cl3) -> Cl3 -> Cl3
spectraldcmpSpecial toSpecial function cliffor =
  let (p,p_bar,eig1,eig2) = projEigs toSpecial cliffor
  in function eig1 * p + function eig2 * p_bar



-- | 'eigvals' calculates the eignenvalues of the cliffor.
-- This is useful for determining if a cliffor is the pole
-- of a function.
eigvals :: Cl3 -> (Cl3,Cl3)
eigvals (reduce -> cliffor) = eigv cliffor
  where
    eigv (r@R{}) = (r,r)
    eigv (v@V3{}) = eigvalsSpecial toR v -- eigvalsR v
    eigv (bv@BV{}) = eigvalsSpecial toI bv -- eigvalsI bv
    eigv (i@I{}) = (i,i)
    eigv (pv@PV{}) = eigvalsSpecial toR pv -- eigvalsR pv
    eigv (h@H{}) = eigvalsSpecial toC h -- eigvalsC h
    eigv (c@C{}) = (c,c)
    eigv (bpv@BPV{})
      | hasNilpotent bpv = (0,0)  -- this case is actually nilpotent
      | isColinear bpv = eigvalsSpecial toC bpv -- eigvalsC bpv
      | otherwise =                          -- transform it so it will be colinear
          let (_,d,_) = boost2colinear bpv
          in eigvalsSpecial toC d -- eigvalsC d
    eigv (od@ODD{}) = eigvalsSpecial toC od -- eigvalsC od
    eigv (tpv@TPV{}) = eigvalsSpecial toI tpv -- eigvalsI tpv
    eigv (aps@APS{})
      | hasNilpotent aps = (toC aps,toC aps)  -- a scalar plus nilpotent
      | isColinear aps = eigvalsSpecial toC aps -- eigvalsC aps
      | otherwise =                          -- transform it so it will be colinear
          let (_,d,_) = boost2colinear aps
          in eigvalsSpecial toC d -- eigvalsC d
--

-- | 'eigvalsSpecial' helper function to calculate Eigenvalues
eigvalsSpecial :: (Cl3 -> Cl3) -> Cl3 -> (Cl3,Cl3)
eigvalsSpecial toSpecial cliffor =
  let (_,_,eig1,eig2) = projEigs toSpecial cliffor
  in (eig1,eig2)


-- | 'project' makes a projector based off of the vector content of the Cliffor.
-- We have safty problem with unreduced values, so it calls reduce first, as a view pattern.
project :: Cl3 -> Cl3
project (reduce -> cliffor) = proj cliffor
  where
    proj (R{}) = PV 0.5 0 0 0.5   -- default to e3 direction
    proj (v@V3{}) = 0.5 * (1 + signum v)
    proj (bv@BV{}) = 0.5 * (1 + signum (toV3 $ mI * toBV bv))
    proj (I{}) = PV 0.5 0 0 0.5   -- default to e3 direction
    proj (pv@PV{}) = 0.5 * (1 + signum (toV3 pv))
    proj (h@H{}) = 0.5 * (1 + signum (toV3 $ mI * toBV h))
    proj (C{}) = PV 0.5 0 0 0.5   -- default to e3 direction
    proj (bpv@BPV{})
      | abs (toV3 bpv + toV3 (mI * toBV bpv)) <= tol = 0.5 * (1 + signum (toV3 bpv))  -- gaurd for equal and opposite
      | otherwise = 0.5 * (1 + signum (toV3 bpv + toV3 (mI * toBV bpv)))
    proj (od@ODD{}) = 0.5 * (1 + signum (toV3 od))
    proj (tpv@TPV{}) = 0.5 * (1 + signum (toV3 $ mI * toBV tpv))
    proj (aps@APS{}) = project.toBPV $ aps


-- | 'boost2colinear' calculates a boost that is perpendicular to both the vector and bivector
-- components, that will mix the vector and bivector parts such that the vector and bivector
-- parts become colinear. This function is a simularity transform such that
-- cliffor = v * d * bar v and returns v, d, and v_bar as a tuple.  First v must be calculated
-- and then d = bar v * cliffor * v. d will have colinear vector and bivector parts.
-- This is somewhat simular to finding the drift frame for an electromagnetic field.
boost2colinear :: Cl3 -> (Cl3, Cl3, Cl3)
boost2colinear cliffor =
  let v = toV3 cliffor  -- extract the vector
      bv = mI * toBV cliffor  -- extract the bivector and turn it into a vector
      invariant = (2 * mI * toBV (v * bv)) / toR (v^2 + bv^2)
      boost = spectraldcmpSpecial toR (exp.(/4).atanh) invariant
      boost_bar = bar boost
      d = boost_bar * cliffor * boost
  in (boost, d, boost_bar)


-- | 'isColinear' takes a Cliffor and determines if the vector part and the bivector part are
-- not at all orthoganl and non-zero.
isColinear :: Cl3 -> Bool
isColinear cliffor = abs (toV3 cliffor) /= 0 && abs (mI * toBV cliffor) /= 0 &&              -- Non-Zero
                     abs (toBV $ signum (toV3 cliffor) * signum (mI * toBV cliffor)) <= tol  -- Not Orthoganl


-- | 'hasNilpotent' takes a Cliffor and determines if the vector part and the bivector part are
-- orthoganl and equal in magnitude, i.e. that it is simular to a nilpotent BPV.
hasNilpotent :: Cl3 -> Bool
hasNilpotent cliffor = abs (toV3 cliffor) /= 0 && abs (mI * toBV cliffor) /= 0 &&                -- Non-Zero
                       abs (toR $ signum (toV3 cliffor) * signum (mI * toBV cliffor)) <= tol &&  -- Orthoganl
                       abs (abs (toV3 cliffor) - abs (toBV cliffor)) <= tol                      -- Equal Magnitude


-- | 'projEigs' function returns complementary projectors and eigenvalues for a Cliffor with specialization.
-- The Cliffor at this point is allready colinear and the Eigenvalue is known to be real, imaginary, or complex.
projEigs :: (Cl3 -> Cl3) -> Cl3 -> (Cl3,Cl3,Cl3,Cl3)
projEigs toSpecial cliffor =
  let p = project cliffor
      p_bar = bar p
      eig1 = 2 * (toSpecial $ p * cliffor * p)
      eig2 = 2 * (toSpecial $ p_bar * cliffor * p_bar)
  in (p,p_bar,eig1,eig2)


-- | 'reduce' function reduces the number of grades in a specialized Cliffor if some are zero
reduce :: Cl3 -> Cl3
reduce r@R{} = r
reduce v@V3{}  
  | abs v <= tol = R 0
  | otherwise = v
reduce bv@BV{}
  | abs bv <= tol = R 0
  | otherwise = bv
reduce i@I{}
  | abs i <= tol = R 0
  | otherwise = i
reduce pv@PV{}
  | abs pv <= tol = R 0
  | abs (toR pv) <= tol = toV3 pv
  | abs (toV3 pv) <= tol = toR pv
  | otherwise = pv
reduce h@H{}
  | abs h <= tol = R 0
  | abs (toR h) <= tol = toBV h
  | abs (toBV h) <= tol = toR h
  | otherwise = h
reduce c@C{}
  | abs c <= tol = R 0
  | abs (toR c) <= tol = toI c
  | abs (toI c) <= tol = toR c  
  | otherwise = c
reduce bpv@BPV{}
  | abs bpv <= tol = R 0
  | abs (toV3 bpv) <= tol = toBV bpv
  | abs (toBV bpv) <= tol = toV3 bpv
  | otherwise = bpv
reduce od@ODD{}
  | abs od <= tol = R 0
  | abs (toV3 od) <= tol = toI od
  | abs (toI od) <= tol = toV3 od
  | otherwise = od
reduce tpv@TPV{}
  | abs tpv <= tol = R 0
  | abs (toBV tpv) <= tol = toI tpv
  | abs (toI tpv) <= tol = toBV tpv
  | otherwise = tpv
reduce aps@APS{}
  | abs aps <= tol = R 0
  | abs (toC aps) <= tol = reduce (toBPV aps)
  | abs (toBPV aps) <= tol = reduce (toC aps)
  | abs (toH aps) <= tol = reduce (toODD aps)
  | abs (toODD aps) <= tol = reduce (toH aps)
  | abs (toPV aps) <= tol = reduce (toTPV aps)
  | abs (toTPV aps) <= tol = reduce (toPV aps)
  | otherwise = aps

-- | 'mI' negative i
mI :: Cl3
mI = I (-1)

-- | 'tol' currently 128*eps
tol :: Cl3
tol = R $ 128 * 1.1102230246251565e-16

tol' :: Double
tol' = 128 * 1.1102230246251565e-16


-- | 'bar' is a Clifford Conjugate, the vector grades are negated
bar :: Cl3 -> Cl3
bar (R a0) = R a0
bar (V3 a1 a2 a3) = V3 (negate a1) (negate a2) (negate a3)
bar (BV a23 a31 a12) = BV (negate a23) (negate a31) (negate a12)
bar (I a123) = I a123
bar (PV a0 a1 a2 a3) = PV a0 (negate a1) (negate a2) (negate a3)
bar (H a0 a23 a31 a12) = H a0 (negate a23) (negate a31) (negate a12)
bar (C a0 a123) = C a0 a123
bar (BPV a1 a2 a3 a23 a31 a12) = BPV (negate a1) (negate a2) (negate a3) (negate a23) (negate a31) (negate a12)
bar (ODD a1 a2 a3 a123) = ODD (negate a1) (negate a2) (negate a3) a123
bar (TPV a23 a31 a12 a123) = TPV (negate a23) (negate a31) (negate a12) a123
bar (APS a0 a1 a2 a3 a23 a31 a12 a123) = APS a0 (negate a1) (negate a2) (negate a3) (negate a23) (negate a31) (negate a12) a123

-- | 'dag' is the Complex Conjugate, the imaginary grades are negated
dag :: Cl3 -> Cl3
dag (R a0) = R a0
dag (V3 a1 a2 a3) = V3 a1 a2 a3
dag (BV a23 a31 a12) = BV (negate a23) (negate a31) (negate a12)
dag (I a123) = I (negate a123)
dag (PV a0 a1 a2 a3) =  PV a0 a1 a2 a3
dag (H a0 a23 a31 a12) = H a0 (negate a23) (negate a31) (negate a12)
dag (C a0 a123) = C a0 (negate a123)
dag (BPV a1 a2 a3 a23 a31 a12) = BPV a1 a2 a3 (negate a23) (negate a31) (negate a12)
dag (ODD a1 a2 a3 a123) = ODD a1 a2 a3 (negate a123)
dag (TPV a23 a31 a12 a123) = TPV (negate a23) (negate a31) (negate a12) (negate a123)
dag (APS a0 a1 a2 a3 a23 a31 a12 a123) = APS a0 a1 a2 a3 (negate a23) (negate a31) (negate a12) (negate a123)

----------------------------------------------------------------------------------------------------------------
-- the to... functions provide a lossy cast from one Cliffor to another
---------------------------------------------------------------------------------------------------------------
-- | 'toR' takes any Cliffor and returns the R portion
toR :: Cl3 -> Cl3
toR (R a0) = R a0
toR V3{} = R 0
toR BV{} = R 0
toR I{} = R 0
toR (PV a0 _ _ _) = R a0
toR (H a0 _ _ _) = R a0
toR (C a0 _) = R a0
toR BPV{} = R 0
toR ODD{} = R 0
toR TPV{} = R 0
toR (APS a0 _ _ _ _ _ _ _) = R a0

-- | 'toV3' takes any Cliffor and returns the V3 portion
toV3 :: Cl3 -> Cl3
toV3 R{} = V3 0 0 0
toV3 (V3 a1 a2 a3) = V3 a1 a2 a3
toV3 BV{} = V3 0 0 0
toV3 I{} = V3 0 0 0
toV3 (PV _ a1 a2 a3) = V3 a1 a2 a3
toV3 H{} = V3 0 0 0
toV3 C{} = V3 0 0 0
toV3 (BPV a1 a2 a3 _ _ _) = V3 a1 a2 a3
toV3 (ODD a1 a2 a3 _) = V3 a1 a2 a3
toV3 TPV{} = V3 0 0 0
toV3 (APS _ a1 a2 a3 _ _ _ _) = V3 a1 a2 a3

-- | 'toBV' takes any Cliffor and returns the BV portion
toBV :: Cl3 -> Cl3
toBV R{} = BV 0 0 0
toBV V3{} = BV 0 0 0
toBV (BV a23 a31 a12) = BV a23 a31 a12
toBV I{} = BV 0 0 0
toBV PV{} = BV 0 0 0
toBV (H _ a23 a31 a12) = BV a23 a31 a12
toBV C{} = BV 0 0 0
toBV (BPV _ _ _ a23 a31 a12) = BV a23 a31 a12
toBV ODD{} = BV 0 0 0
toBV (TPV a23 a31 a12 _) = BV a23 a31 a12
toBV (APS _ _ _ _ a23 a31 a12 _) = BV a23 a31 a12

-- | 'toI' takes any Cliffor and returns the I portion
toI :: Cl3 -> Cl3
toI R{} = I 0
toI V3{} = I 0
toI BV{} = I 0
toI (I a123) = I a123
toI PV{} = I 0
toI H{} = I 0
toI (C _ a123) = I a123
toI BPV{} = I 0
toI (ODD _ _ _ a123) = I a123
toI (TPV _ _ _ a123) = I a123
toI (APS _ _ _ _ _ _ _ a123) = I a123

-- | 'toPV' takes any Cliffor and returns the PV poriton
toPV :: Cl3 -> Cl3
toPV (R a0) = PV a0 0 0 0
toPV (V3 a1 a2 a3) = PV 0 a1 a2 a3
toPV BV{} = PV 0 0 0 0
toPV I{} = PV 0 0 0 0
toPV (PV a0 a1 a2 a3) = PV a0 a1 a2 a3
toPV (H a0 _ _ _) = PV a0 0 0 0
toPV (C a0 _) = PV a0 0 0 0
toPV (BPV a1 a2 a3 _ _ _) = PV 0 a1 a2 a3
toPV (ODD a1 a2 a3 _) = PV a1 a2 a3 0
toPV TPV{} = PV 0 0 0 0
toPV (APS a0 a1 a2 a3 _ _ _ _) = PV a0 a1 a2 a3

-- | 'toH' takes any Cliffor and returns the H portion
toH :: Cl3 -> Cl3
toH (R a0) = H a0 0 0 0
toH V3{} = H 0 0 0 0
toH (BV a23 a31 a12) = H 0 a23 a31 a12
toH (I _) = H 0 0 0 0
toH (PV a0 _ _ _) = H a0 0 0 0
toH (H a0 a23 a31 a12) = H a0 a23 a31 a12
toH (C a0 _) = H a0 0 0 0
toH (BPV _ _ _ a23 a31 a12) = H 0 a23 a31 a12
toH ODD{} = H 0 0 0 0
toH (TPV a23 a31 a12 _) = H 0 a23 a31 a12
toH (APS a0 _ _ _ a23 a31 a12 _) = H a0 a23 a31 a12

-- | 'toC' takes any Cliffor and returns the C portion
toC :: Cl3 -> Cl3
toC (R a0) = C a0 0
toC V3{} = C 0 0
toC BV{} = C 0 0
toC (I a123) = C 0 a123
toC (PV a0 _ _ _) = C a0 0
toC (H a0 _ _ _) = C a0 0
toC (C a0 a123) = C a0 a123
toC BPV{} = C 0 0
toC (ODD _ _ _ a123) = C 0 a123
toC (TPV _ _ _ a123) = C 0 a123
toC (APS a0 _ _ _ _ _ _ a123) = C a0 a123

-- | 'toBPV' takes any Cliffor and returns the BPV portion
toBPV :: Cl3 -> Cl3
toBPV R{} = BPV 0 0 0 0 0 0
toBPV (V3 a1 a2 a3) = BPV a1 a2 a3 0 0 0
toBPV (BV a23 a31 a12) = BPV 0 0 0 a23 a31 a12
toBPV I{} = BPV 0 0 0 0 0 0
toBPV (PV _ a1 a2 a3) = BPV a1 a2 a3 0 0 0
toBPV (H _ a23 a31 a12) = BPV 0 0 0 a23 a31 a12
toBPV C{} = BPV 0 0 0 0 0 0
toBPV (BPV a1 a2 a3 a23 a31 a12) = BPV a1 a2 a3 a23 a31 a12
toBPV (ODD a1 a2 a3 _) = BPV a1 a2 a3 0 0 0
toBPV (TPV a23 a31 a12 _) = BPV 0 0 0 a23 a31 a12
toBPV (APS _ a1 a2 a3 a23 a31 a12 _) = BPV a1 a2 a3 a23 a31 a12

-- | 'toODD' takes any Cliffor and returns the ODD portion
toODD :: Cl3 -> Cl3
toODD R{} = ODD 0 0 0 0
toODD (V3 a1 a2 a3) = ODD a1 a2 a3 0
toODD BV{} = ODD 0 0 0 0
toODD (I a123) = ODD 0 0 0 a123
toODD (PV _ a1 a2 a3) = ODD a1 a2 a3 0
toODD H{} = ODD 0 0 0 0
toODD (C _ a123) = ODD 0 0 0 a123
toODD (BPV a1 a2 a3 _ _ _) = ODD a1 a2 a3 0
toODD (ODD a1 a2 a3 a123) = ODD a1 a2 a3 a123
toODD (TPV _ _ _ a123) = ODD 0 0 0 a123
toODD (APS _ a1 a2 a3 _ _ _ a123) = ODD a1 a2 a3 a123

-- | 'toTPV' takes any Cliffor and returns the TPV portion
toTPV :: Cl3 -> Cl3
toTPV R{} = TPV 0 0 0 0
toTPV V3{} = TPV 0 0 0 0
toTPV (BV a23 a31 a12) = TPV a23 a31 a12 0
toTPV (I a123) = TPV 0 0 0 a123
toTPV PV{} = TPV 0 0 0 0
toTPV (H _ a23 a31 a12) = TPV a23 a31 a12 0
toTPV (C _ a123) = TPV 0 0 0 a123
toTPV (BPV _ _ _ a23 a31 a12) = TPV a23 a31 a12 0
toTPV (ODD _ _ _ a123) = TPV 0 0 0 a123
toTPV (TPV a23 a31 a12 a123) = TPV a23 a31 a12 a123
toTPV (APS _ _ _ _ a23 a31 a12 a123) = TPV a23 a31 a12 a123

-- | 'toAPS' takes any Cliffor and returns the APS portion
toAPS :: Cl3 -> Cl3
toAPS (R a0) = APS a0 0 0 0 0 0 0 0
toAPS (V3 a1 a2 a3) = APS 0 a1 a2 a3 0 0 0 0
toAPS (BV a23 a31 a12) = APS 0 0 0 0 a23 a31 a12 0
toAPS (I a123) = APS 0 0 0 0 0 0 0 a123
toAPS (PV a0 a1 a2 a3) = APS a0 a1 a2 a3 0 0 0 0
toAPS (H a0 a23 a31 a12) = APS a0 0 0 0 a23 a31 a12 0
toAPS (C a0 a123) = APS a0 0 0 0 0 0 0 a123
toAPS (BPV a1 a2 a3 a23 a31 a12) = APS 0 a1 a2 a3 a23 a31 a12 0
toAPS (ODD a1 a2 a3 a123) = APS 0 a1 a2 a3 0 0 0 a123
toAPS (TPV a23 a31 a12 a123) = APS 0 0 0 0 a23 a31 a12 a123
toAPS (APS a0 a1 a2 a3 a23 a31 a12 a123) = APS a0 a1 a2 a3 a23 a31 a12 a123

-- derivatives of the functions in the Fractional Class for use in Jordan NF functon implemetnation
recip' :: Cl3 -> Cl3
recip' x = negate.recip $ x * x   -- pole at 0

exp' :: Cl3 -> Cl3
exp' = exp

log' :: Cl3 -> Cl3
log' = recip  -- pole at 0

sqrt' :: Cl3 -> Cl3
sqrt' x = 0.5 * recip (sqrt x)   -- pole at 0

sin' :: Cl3 -> Cl3
sin' = cos

cos' :: Cl3 -> Cl3
cos' = negate.sin

tan' :: Cl3 -> Cl3
tan' x = recip (cos x) * recip (cos x)  -- pole at pi/2*n for all integers

asin' :: Cl3 -> Cl3
asin' x = recip.sqrt $ 1 - (x * x)  -- pole at +/-1

acos' :: Cl3 -> Cl3
acos' x = negate.recip.sqrt $ 1 - (x * x)  -- pole at +/-1

atan' :: Cl3 -> Cl3
atan' x = recip $ 1 + (x * x)  -- pole at +/-i

sinh' :: Cl3 -> Cl3
sinh' = cosh

cosh' :: Cl3 -> Cl3
cosh' = sinh

tanh' :: Cl3 -> Cl3
tanh' x = recip (cosh x) * recip (cosh x)

asinh' :: Cl3 -> Cl3
asinh' x = recip.sqrt $ (x * x) + 1  -- pole at +/-i

acosh' :: Cl3 -> Cl3
acosh' x = recip $ sqrt (x - 1) * sqrt (x + 1)  -- pole at +/-1

atanh' :: Cl3 -> Cl3
atanh' x = recip $ 1 - (x * x)  -- pole at +/-1


-------------------------------------------------------------------
-- 
-- Instance of Cl3 types with the "Foreign.Storable" library.
--  
-- For use with high performance data structures like Data.Vector.Storable
-- or Data.Array.Storable
-- 
-------------------------------------------------------------------

-- | Cl3 instance of Storable uses the APS constructor as its standard interface.
-- "peek" returns a cliffor constructed with APS. "poke" converts a cliffor to APS.
instance Storable Cl3 where
  sizeOf _ = 8 * sizeOf (undefined :: Double)
  alignment _ = sizeOf (undefined :: Double)
  peek ptr = do
        a0 <- peek (offset 0)
        a1 <- peek (offset 1)
        a2 <- peek (offset 2)
        a3 <- peek (offset 3)
        a23 <- peek (offset 4)
        a31 <- peek (offset 5)
        a12 <- peek (offset 6)
        a123 <- peek (offset 7)
        return $ APS a0 a1 a2 a3 a23 a31 a12 a123
          where
            offset i = (castPtr ptr :: Ptr Double) `plusPtr` (i*8)
  
  poke ptr (toAPS -> APS a0 a1 a2 a3 a23 a31 a12 a123) = do
        poke (offset 0) a0
        poke (offset 1) a1
        poke (offset 2) a2
        poke (offset 3) a3
        poke (offset 4) a23
        poke (offset 5) a31
        poke (offset 6) a12
        poke (offset 7) a123
          where
            offset i = (castPtr ptr :: Ptr Double) `plusPtr` (i*8)
  poke _ _ = error "Serious Issues with poke in Cl3.Storable"




-------------------------------------------------------------------
-- 
-- Random Instance of Cl3 types with the "System.Random" library.
-- 
--
-- Random helper functions will be based on the "abs x * signum x" decomposition
-- for the single grade elements. The "abs x" will be the random magnitude that
-- is by the default [0,1), and the "signum x" part will be a random direction
-- of a vector or the sign of a scalar. The multi-grade elements will be constructed from
-- a combination of the single grade generators.  Each grade will be evenly
-- distributed across the range.
-- 
-------------------------------------------------------------------

-- | 'Random' instance for the 'System.Random' library
instance Random Cl3 where
  randomR (minAbs,maxAbs) g =
             case randomR (fromEnum (minBound :: ConCl3), fromEnum (maxBound :: ConCl3)) g of
               (r, g') -> case toEnum r of
                            ConR -> rangeR (minAbs,maxAbs) g'
                            ConV3 -> rangeV3 (minAbs,maxAbs) g'
                            ConBV -> rangeBV (minAbs,maxAbs) g'
                            ConI -> rangeI (minAbs,maxAbs) g'
                            ConPV -> rangePV (minAbs,maxAbs) g'
                            ConH -> rangeH (minAbs,maxAbs) g'
                            ConC -> rangeC (minAbs,maxAbs) g'
                            ConBPV -> rangeBPV (minAbs,maxAbs) g'
                            ConODD -> rangeODD (minAbs,maxAbs) g'
                            ConTPV -> rangeTPV (minAbs,maxAbs) g'
                            ConAPS -> rangeAPS (minAbs,maxAbs) g'

  random = randomR (0,1)



-- | 'ConCl3' Bounded Enum Algebraic Data Type of constructors of Cl3
data ConCl3 = ConR
            | ConV3
            | ConBV
            | ConI
            | ConPV
            | ConH
            | ConC
            | ConBPV
            | ConODD
            | ConTPV
            | ConAPS
  deriving (Bounded, Enum)




-- | 'randR' random Real Scalar (Grade 0) with random magnitude and random sign
randR :: RandomGen g => g -> (Cl3, g)
randR = rangeR (0,1)


-- | 'rangeR' random Real Scalar (Grade 0) with random magnitude within a range and a random sign
rangeR :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeR = scalarHelper R


-- | 'randV3' random Vector (Grade 1) with random magnitude and random direction
-- the direction is using spherical coordinates
randV3 :: RandomGen g => g -> (Cl3, g)
randV3 = rangeV3 (0,1)


-- | 'rangeV3' random Vector (Grade 1) with random magnitude within a range and a random direction
rangeV3 :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeV3 = vectorHelper V3


-- | 'randBV' random Bivector (Grade 2) with random magnitude and random direction
-- the direction is using spherical coordinates
randBV :: RandomGen g => g -> (Cl3, g)
randBV = rangeBV (0,1)


-- | 'rangeBV' random Bivector (Grade 2) with random magnitude in a range and a random direction
rangeBV :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeBV = vectorHelper BV


-- | 'randI' random Imaginary Scalar (Grade 3) with random magnitude and random sign
randI :: RandomGen g => g -> (Cl3, g)
randI = rangeI (0,1)


-- | 'rangeI' random Imaginary Scalar (Grade 3) with random magnitude within a range and random sign
rangeI :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeI = scalarHelper I


-- | 'randPV' random Paravector made from random Grade 0 and Grade 1 elements
randPV :: RandomGen g => g -> (Cl3, g)
randPV = rangePV (0,1)


-- | 'rangePV' random Paravector made from random Grade 0 and Grade 1 elements within a range
rangePV :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangePV (lo, hi) g =
  let (r, g') = rangeR (lo, hi) g
      (v3, g'') = rangeV3 (lo, hi) g'
  in (r + v3, g'')


-- | 'randH' random Quaternion made from random Grade 0 and Grade 2 elements
randH :: RandomGen g => g -> (Cl3, g)
randH = rangeH (0,1)


-- | 'rangeH' random Quaternion made from random Grade 0 and Grade 2 elements within a range
rangeH :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeH (lo, hi) g =
  let (r, g') = rangeR (lo, hi) g
      (bv, g'') = rangeBV (lo, hi) g'
  in (r + bv, g'')


-- | 'randC' random combination of Grade 0 and Grade 3
randC :: RandomGen g => g -> (Cl3, g)
randC = rangeC (0,1)


-- | 'rangeC' random combination of Grade 0 and Grade 3 within a range
rangeC :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeC (lo, hi) g =
  let (r, g') = rangeR (lo, hi) g
      (i, g'') = rangeI (lo, hi) g'
  in (r + i, g'')


-- | 'randBPV' random combination of Grade 1 and Grade 2
randBPV :: RandomGen g => g -> (Cl3, g)
randBPV = rangeBPV (0,1)


-- | 'rangeBPV' random combination of Grade 1 and Grade 2 within a range
rangeBPV :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeBPV (lo, hi) g =
  let (v3, g') = rangeV3 (lo, hi) g
      (bv, g'') = rangeBV (lo, hi) g'
  in (v3 + bv, g'')


-- | 'randODD' random combination of Grade 1 and Grade 3
randODD :: RandomGen g => g -> (Cl3, g)
randODD = rangeODD (0,1)


-- | 'rangeODD' random combination of Grade 1 and Grade 3 within a range
rangeODD :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeODD (lo, hi) g =
  let (v3, g') = rangeV3 (lo, hi) g
      (i, g'') = rangeI (lo, hi) g'
  in (v3 + i, g'')


-- | 'randTPV' random combination of Grade 2 and Grade 3
randTPV :: RandomGen g => g -> (Cl3, g)
randTPV = rangeTPV (0,1)


-- | 'rangeTPV' random combination of Grade 2 and Grade 3 within a range
rangeTPV :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeTPV (lo, hi) g =
  let (bv, g') = rangeBV (lo, hi) g
      (i, g'') = rangeI (lo, hi) g'
  in (bv + i, g'')


-- | 'randAPS' random combination of all 4 grades
randAPS :: RandomGen g => g -> (Cl3, g)
randAPS = rangeAPS (0,1)


-- | 'rangeAPS' random combination of all 4 grades within a range
rangeAPS :: RandomGen g => (Cl3, Cl3) -> g -> (Cl3, g)
rangeAPS (lo, hi) g =
  let (pv, g') = rangePV (lo, hi) g
      (tpv, g'') = rangeTPV (lo, hi) g'
  in (pv + tpv, g'')


-------------------------------------------------------------------
-- Additional Random generators
-------------------------------------------------------------------
-- | 'randUnitV3' a unit vector with a random direction
randUnitV3 :: RandomGen g => g -> (Cl3, g)
randUnitV3 g =
  let (theta, g') = randomR (0,pi) g
      (phi, g'') = randomR (0,2*pi) g'
  in (V3 (sin theta * cos phi) (sin theta * sin phi) (cos theta), g'')


-- | 'randProjector' a projector with a random direction
randProjector :: RandomGen g => g -> (Cl3, g)
randProjector g =
  let (v3, g') = randUnitV3 g
  in (0.5 + 0.5 * v3, g')


-- | 'randNilpotent' a nilpotent element with a random orientation
randNilpotent :: RandomGen g => g -> (Cl3, g)
randNilpotent g =
  let (p, g') = randProjector g
      (v, g'') = randUnitV3 g'
      vnormal = signum $ I (-1) * toBV ( toV3 p * v)  -- unit vector normal to the projector
  in (toBPV $ vnormal * p, g'')


-------------------------------------------------------------------
-- helper functions
-------------------------------------------------------------------
magHelper :: RandomGen g => (Cl3, Cl3) -> g -> (Double, g)
magHelper (lo, hi) g =
  let R lo' = abs lo
      R hi' = abs hi
  in randomR (lo', hi') g


scalarHelper :: RandomGen g => (Double -> Cl3) -> (Cl3, Cl3) -> g -> (Cl3, g)
scalarHelper con rng g =
  let (mag, g') = magHelper rng g
      (sign, g'') = random g'
  in if sign
     then (con mag, g'')
     else (con (negate mag), g'')


vectorHelper :: RandomGen g => (Double -> Double -> Double -> Cl3) -> (Cl3, Cl3) -> g -> (Cl3, g)
vectorHelper con rng g =
  let (mag, g') = magHelper rng g
      (theta, g'') = randomR (0,pi) g'
      (phi, g''') = randomR (0,2*pi) g''
  in (con (mag * sin theta * cos phi) (mag * sin theta * sin phi) (mag * cos theta), g''')

