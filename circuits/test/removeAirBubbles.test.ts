import { assert } from 'chai';
import { WasmTester, wasm } from 'circom_tester';
import path from 'path';
import { GRID_HEIGHT, GRID_WIDTH } from '../config';
import { Colors } from '../types/circuitFunctions.types';
import { calculateLabeledWitness } from './utils/calculateLabeledWitness';

const puzzles: {
  [key: number]: {
    [gridStage in 'initial' | 'target']: Colors[][];
  };
} = {
  1: {
    initial: [
      [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    target: [
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
  },
  2: {
    initial: [
      [0, 0, 2, 0, 3, 3, 0, 1, 0, 0, 0, 0],
      [0, 2, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      [2, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 2, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      [0, 0, 2, 0, 3, 3, 0, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    target: [
      [2, 3, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 3, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
  },
  3: {
    initial: [
      [1, 1, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0],
      [2, 3, 0, 0, 0, 0, 3, 1, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 3, 0, 0, 0, 0, 3, 1, 0, 0, 0, 0],
      [1, 1, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0],
    ],
    target: [
      [1, 1, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 3, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [2, 3, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
  },
};

describe.only('removeairbubbles circuit', () => {
  let circuit: WasmTester;

  const sanityCheck = true;
  const initialGrid = puzzles[1].initial;

  before(async () => {
    circuit = await wasm(
      path.join(__dirname, '../circuits/test/removeairbubbles_test.circom')
    );
  });

  it('produces a witness with valid constraints', async () => {
    const witness = await circuit.calculateWitness(
      { grid: initialGrid, onOff: 1 },
      sanityCheck
    );

    await circuit.checkConstraints(witness);
  });

  it('has expected witness values for onOff == 1', async () => {
    const witness = await calculateLabeledWitness(
      circuit,
      { grid: initialGrid, onOff: 1 },
      sanityCheck
    );

    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 8; j++) {
        assert.propertyVal(
          witness,
          `main.out[${i}][${j}]`,
          String(puzzles[1].target[i][j])
        );
      }
    }
  });

  it('has expected witness values for onOff == 0', async () => {
    const witness = await calculateLabeledWitness(
      circuit,
      { grid: initialGrid, onOff: 0 },
      sanityCheck
    );

    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 8; j++) {
        assert.propertyVal(
          witness,
          `main.out[${i}][${j}]`,
          String(initialGrid[i][j])
        );
      }
    }
  });

  it('produces expected witness values', async () => {
    const witness = await calculateLabeledWitness(
      circuit,
      { grid: initialGrid, onOff: 0 },
      sanityCheck
    );

    assert.notPropertyVal(
      witness,
      'main.out[0][0]',
      String(puzzles[2].target[0][0])
    );
  });

  [1, 2, 3].forEach((lvl: number) => {
    it(`removeairbubbles witness values for level ${lvl} equals removeairbubbles function return values`, async () => {
      const witness = await calculateLabeledWitness(
        circuit,
        {
          grid: puzzles[lvl].initial,
          onOff: 1,
        },
        sanityCheck
      );

      for (let i = 0; i < GRID_WIDTH; i++) {
        for (let j = 0; j < GRID_HEIGHT; j++) {
          assert.propertyVal(
            witness,
            `main.out[${i}][${j}]`,
            String(puzzles[lvl].target[i][j])
          );
        }
      }
    });
  });
});
