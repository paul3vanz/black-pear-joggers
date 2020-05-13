export enum LoadingStates {
  INIT = 'INIT',
  LOADING = 'LOADING',
  LOADED = 'LOADED'
}

export interface ErrorState {
  error: string;
}

export type LoadingState = LoadingStates | ErrorState;

export function getError(callState: LoadingState): string | null {
  if ((callState as ErrorState).error !== undefined) {
    return (callState as ErrorState).error;
  }
  return null;
}
