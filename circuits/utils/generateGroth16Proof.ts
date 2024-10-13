// @ts-ignore
import { groth16 } from 'snarkjs';
import { InputSignals, Proof } from '../types/proof.types';

export async function generateGroth16Proof(
  input: InputSignals,
  wasmPath: string,
  zkeyPath: string
): Promise<{ proof: Proof; publicSignals: `0x${string}`[] }> {
  let _proof, _publicSignals;
  try {
    ({ proof: _proof, publicSignals: _publicSignals } = await groth16.fullProve(
      input,
      wasmPath,
      zkeyPath
    ));
  } catch (err) {
    // prettier-ignore
    if ((err as Error).message.includes('Error in template ForceEqualIfEnabled_15')) {
      throw new Error('Wrong answer, try again!');
    }

    throw new Error((err as Error).message);
  }

  return { proof: _proof, publicSignals: _publicSignals };
}
