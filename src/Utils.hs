module Utils where

import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer
import Control.Concurrent
import Control.Concurrent.STM
import Control.Concurrent.STM.TVar
import Control.Concurrent.STM.TQueue
import Control.Arrow (first)
import Data.Map as Map
import Data.List.Index
import Parser

type AppT = ReaderT MarsData (StateT [ProgramCounter] (StateT Instruction (WriterT String IO)))

type Memory = TVar (Map Int Instruction)

type ProgramCounter = Int

data MarsData = MarsData {
  queue  :: TQueue ThreadId,
  memory :: Memory
}

initMem :: [(Int, Program)] -> STM Memory
initMem progs = newTVar mem 
  where 
    iMem = Map.fromList $ zip [0..8000] (replicate 8000 $ I2 DAT (Direct 0))
    mem = Prelude.foldl1 Map.union (fmap addrProgs progs ++ [iMem]) 

addrProgs :: (Int,Program) -> Map Int Instruction
addrProgs (i,prog) = Map.fromList $ fmap (\ (x,y) -> (i*1000+x,y)) (zip [0..] prog)

addTask :: ProgramCounter -> AppT ()
addTask pc = do
  tasks <- lift get
  lift $ put (pc:tasks)
  
endTask :: AppT ()
endTask = do
  tasks <- lift get
  lift $ put $ reverse tasks

updatePc :: AppT ()
updatePc = do
  pc <- getPc
  putPc (pc + 1)

getPc :: AppT ProgramCounter
getPc = do
  tasks <- lift get
  return $ head tasks

putPc :: ProgramCounter -> AppT ()
putPc pc = do
  (_:tasks) <- lift get 
  lift $ put (pc:tasks)

