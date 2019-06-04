program project1;

uses
  SysUtils, Contnrs;

type
  TCliffordError = (ceSuccess, ceEmptyStack, ceUnrecognisedInstruction, ceInvalidInput, ceMissingArgument, ceDivByZero, ceException);

const
  INS_PUSH     = 0;
  INS_POP      = 1;
  INS_ADD      = 2;
  INS_SUBTRACT = 3;
  INS_MULTIPLY = 4;
  INS_DIVIDE   = 5;

function GetNextNumber(var Input: string; out Value: LongInt): TCliffordError;
var
  StrPos: SizeInt;
  CurrentEntry: string;
begin
  Result := ceSuccess;

  StrPos := Pos(' ', Input);
  if StrPos > 0 then
  begin
    CurrentEntry := Copy(Input, 1, StrPos - 1);
    { Remove entry from the list }
    Delete(Input, 1, StrPos);

  end else
  begin
    { Last entry in the list }
    CurrentEntry := Input;
    Input := '';
  end;

  if Length(CurrentEntry) = 0 then
    Result := ceMissingArgument
  else if not TryStrToInt(CurrentEntry, Value) then
    Result := ceInvalidInput;
end;

function GetTopTwo(StackObject: TStack; out Top: Integer; out SecondTop: Integer): TCliffordError;
begin
  Result := ceSuccess;

  { Check to see if the stack is empty or not }
  if not StackObject.AtLeast(2) then
  begin
    Result := ceEmptyStack;
    Exit;
  end;

  Top := Integer(StackObject.Pop);
  SecondTop := Integer(StackObject.Pop);
end;


function Clifford(Input: string; out Answer: Integer): TCliffordError;
var
  NumberStack: TStack;
  CurrentInstruction, Argument1, Argument2: Integer;
begin
  try
    { Remove leading and trailing spaces }
    Input := Trim(Input);

    if Length(Input) = 0 then
    begin
      { Though this would be trapped below, "Missing argument" is a bit nicer
        than "Empty stack" }
      Result := ceMissingArgument;
      Exit;
    end;

    NumberStack := TStack.Create;
    try
      while Length(Input) > 0 do
      begin

        Result := GetNextNumber(Input, CurrentInstruction);
        if Result <> ceSuccess then
          { Something went wrong }
          Exit;

        { Process the new CurrentInstruction }
        case CurrentInstruction of
        INS_PUSH: { Push 1 Argument }
          begin
            Result := GetNextNumber(Input, Argument1);
            if Result <> ceSuccess then
              { Something went wrong }
              Exit;

            NumberStack.Push(Pointer(Argument1));
          end;
        INS_POP: { Pop / Discard }
          begin
            { Check to see if the stack is empty or not }
            if not NumberStack.AtLeast(1) then
            begin
              Result := ceEmptyStack;
              Exit;
            end;

            NumberStack.Pop;
          end;

        INS_ADD: { Add top two entries on the stack }
          begin
            Result := GetTopTwo(NumberStack, Argument1, Argument2);
            if Result <> ceSuccess then
              { Something went wrong }
              Exit;

            NumberStack.Push(Pointer(Argument2 + Argument1));
          end;

        INS_SUBTRACT: { Subtract the top entry from the second top entry }
          begin
            { e.g. if the stack contains (3 5), with 3 being at the top, the
              result is (2), not (-2) }
            Result := GetTopTwo(NumberStack, Argument1, Argument2);
            if Result <> ceSuccess then
              { Something went wrong }
              Exit;

            NumberStack.Push(Pointer(Argument2 - Argument1));
          end;

        INS_MULTIPLY: { Multiply th top two entries on the stack }
          begin
            Result := GetTopTwo(NumberStack, Argument1, Argument2);
            if Result <> ceSuccess then
              { Something went wrong }
              Exit;

            NumberStack.Push(Pointer(Argument2 * Argument1));
          end;

        INS_DIVIDE: { Divide the top entry by the second top entry }
          begin
            { e.g. if the stack contains (2 10), with 2 being at the top, the
              result is (10), not (0) }
            Result := GetTopTwo(NumberStack, Argument1, Argument2);
            if Result <> ceSuccess then
              { Something went wrong }
              Exit;

            { Trap division by zero instead of raising an exception }
            if Argument1 = 0 then
            begin
              Result := ceDivByZero;
              Exit;
            end;

            NumberStack.Push(Pointer(Argument2 div Argument1));
          end;

        { Add new instructions here (after defining its constant above with the
          others) }

        else
          begin
            { Unrecognised instruction }
            Result := ceUnrecognisedInstruction;
            Exit;
          end;
        end;

        { In case there was a double space }
        Input := TrimLeft(Input);
      end;

      { Check to see if the stack is empty or not }
      if not NumberStack.AtLeast(1) then
      begin
        Result := ceEmptyStack;
        Exit;
      end;

      Answer := Integer(NumberStack.Pop);
      Result := ceSuccess;

    finally
      NumberStack.Free;
    end;

  except
    Result := ceException;
  end;
end;

var
  Instruction: string; Answer: Integer;
begin
  repeat
    Write('Input number sequence (or type ''exit'' to exit): ');
    ReadLn(Instruction);

    if (UpperCase(Instruction) = 'EXIT') then
      Break;

    case Clifford(Instruction, Answer) of
    ceSuccess:
      WriteLn('Top of stack: ', Answer, #10);
    ceEmptyStack:
      WriteLn('ERROR: Empty stack'#10);
    ceUnrecognisedInstruction:
      WriteLn('ERROR: An instruction was not recognised'#10);
    ceInvalidInput:
      WriteLn('ERROR: The input contains non-numeric characters'#10);
    ceMissingArgument:
      WriteLn('ERROR: An argument is missing'#10);
    ceDivByZero:
      WriteLn('ERROR: Division by zero'#10);
    ceException:
      WriteLn('ERROR: Unexpected error'#10);
    end;
  until False;
end.

