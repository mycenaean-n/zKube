'use client';
import { createContext, memo, useEffect, useState } from 'react';
import {
  PuzzleContext as PuzzleContextType,
  PuzzleFunctions,
  Puzzle as PuzzleType,
} from 'types/Puzzle';
import { Actions } from './actions/Actions';
import { Scene } from './scene/Scene';

type GameMode = 'singleplayer' | 'multiplayer';

export const PuzzleContext = createContext<PuzzleContextType>({
  initConfig: { initialGrid: [], finalGrid: [], availableFunctions: [] },
  functions: { remaining: [], chosen: [], available: [] },
  setFunctions: () => {},
});

function Puzzle({
  initConfig,
  id,
  gameMode,
}: {
  initConfig: PuzzleType;
  id: string;
  gameMode: GameMode;
}) {
  const [functions, setFunctions] = useState<PuzzleFunctions>({
    remaining: initConfig.availableFunctions.filter(
      (funcName) => funcName !== 'EMPTY'
    ),
    chosen: [],
    available: initConfig.availableFunctions,
  });

  useEffect(() => {
    setFunctions({
      remaining: initConfig.availableFunctions.filter(
        (funcName) => funcName !== 'EMPTY'
      ),
      chosen: [],
      available: initConfig.availableFunctions,
    });
  }, [JSON.stringify(initConfig), id]);

  return (
    <PuzzleContext.Provider
      value={{
        initConfig,
        functions,
        setFunctions,
      }}
    >
      <div className="m-auto flex flex-grow flex-col">
        <Scene />
        <Actions {...{ id, gameMode }} />
      </div>
    </PuzzleContext.Provider>
  );
}

export const PuzzleMemoized = memo(Puzzle, (prevProps, nextProps) => {
  return (
    JSON.stringify(prevProps.initConfig) ===
    JSON.stringify(nextProps.initConfig)
  );
});
