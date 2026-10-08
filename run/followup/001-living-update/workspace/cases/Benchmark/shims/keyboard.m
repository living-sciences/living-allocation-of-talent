function keyboard(varargin)
  % Batch-mode shim: the shipped code uses keyboard as a debug trap.
  % In non-interactive Octave the real keyboard spins on EOF, so make it
  % a no-op that lets execution continue past the trap.
  warning('keyboard_shim:trap','keyboard() debug trap reached; continuing (batch mode).');
end
