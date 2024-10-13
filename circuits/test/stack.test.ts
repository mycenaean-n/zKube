import { assert } from 'chai';
import { WasmTester, wasm } from 'circom_tester';
import path from 'path';
import { GRID_HEIGHT, GRID_WIDTH } from '../config';
import { Puzzle } from '../types/circuitFunctions.types';
import { argumentBuilder } from '../utils/circuitFunctions';
import { gridMutator } from '../utils/transformers/gridMutator';
import { calculateLabeledWitness } from './utils/calculateLabeledWitness';
const puzzles: Puzzle = require('../data/test.puzzles.json');

describe.only('stack circuit', () => {
  let circuit: WasmTester;
  const sanityCheck = true;
  const initialGrid = puzzles[0.1].initial;

  before(async () => {
    circuit = await wasm(
      path.join(__dirname, '../circuits/test/stack_test.circom')
    );
  });

  it('produces a witness with valid constraints', async () => {
    const witness = await circuit.calculateWitness(
      { grid: initialGrid, onOff: 1, color: 1 },
      sanityCheck
    );

    await circuit.checkConstraints(witness);
  });

  it('has expected witness values', async () => {
    const witness = await calculateLabeledWitness(
      circuit,
      { grid: initialGrid, onOff: 1, color: 1 },
      sanityCheck
    );

    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 8; j++) {
        assert.propertyVal(
          witness,
          `main.out[${i}][${j}]`,
          String(puzzles[0.1].stack[i][j])
        );
      }
    }
  });

  it('produces expected witness values', async () => {
    const witness = await calculateLabeledWitness(
      circuit,
      { grid: initialGrid, onOff: 1, color: 1 },
      sanityCheck
    );

    assert.notPropertyVal(
      witness,
      'main.out[0][0]',
      String(puzzles[0.1].target[0][3])
    );
  });

  [1, 2, 3, 4].forEach((i: number) => {
    it(`stack witness values for iteration ${i} equals stack function return values`, async () => {
      const argument =
        i === 1
          ? 'STACK_RED'
          : i === 2
            ? 'STACK_BLUE'
            : i === 3
              ? 'STACK_YELLOW'
              : 'STACK_YELLOW';

      const [onOff, color] = argumentBuilder(argument);

      const witness = await calculateLabeledWitness(
        circuit,
        { grid: puzzles[0.1].initial, onOff, color },
        sanityCheck
      );

      const targetGrid = gridMutator(initialGrid, [argument]);

      for (let i = 0; i < GRID_WIDTH; i++) {
        for (let j = 0; j < GRID_HEIGHT; j++) {
          assert.propertyVal(
            witness,
            `main.out[${i}][${j}]`,
            String(targetGrid[i][j])
          );
        }
      }
    });
  });
});
