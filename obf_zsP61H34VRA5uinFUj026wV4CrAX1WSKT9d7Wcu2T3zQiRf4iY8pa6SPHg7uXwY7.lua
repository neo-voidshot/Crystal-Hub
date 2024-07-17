--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.6) ~  Much Love, Ferib 

]]--

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			local FlatIdent_12703 = 0;
			while true do
				if (FlatIdent_12703 == 0) then
					repeatNext = StrToNumber(Sub(byte, 1, 1));
					return "";
				end
			end
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			local FlatIdent_2BD95 = 0;
			while true do
				if (FlatIdent_2BD95 == 0) then
					Len = gBits32();
					if (Len == 0) then
						return "";
					end
					break;
				end
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local FlatIdent_23BE8 = 0;
			local Descriptor;
			while true do
				if (FlatIdent_23BE8 == 0) then
					Descriptor = gBits8();
					if (gBit(Descriptor, 1, 1) == 0) then
						local Type = gBit(Descriptor, 2, 3);
						local Mask = gBit(Descriptor, 4, 6);
						local Inst = {gBits16(),gBits16(),nil,nil};
						if (Type == 0) then
							local FlatIdent_8199B = 0;
							while true do
								if (FlatIdent_8199B == 0) then
									Inst[3] = gBits16();
									Inst[4] = gBits16();
									break;
								end
							end
						elseif (Type == 1) then
							Inst[3] = gBits32();
						elseif (Type == 2) then
							Inst[3] = gBits32() - (2 ^ 16);
						elseif (Type == 3) then
							Inst[3] = gBits32() - (2 ^ 16);
							Inst[4] = gBits16();
						end
						if (gBit(Mask, 1, 1) == 1) then
							Inst[2] = Consts[Inst[2]];
						end
						if (gBit(Mask, 2, 2) == 1) then
							Inst[3] = Consts[Inst[3]];
						end
						if (gBit(Mask, 3, 3) == 1) then
							Inst[4] = Consts[Inst[4]];
						end
						Instrs[Idx] = Inst;
					end
					break;
				end
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				local FlatIdent_1076E = 0;
				while true do
					if (1 == FlatIdent_1076E) then
						if (Enum <= 26) then
							if (Enum <= 12) then
								if (Enum <= 5) then
									if (Enum <= 2) then
										if (Enum <= 0) then
											local B;
											local A;
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
										elseif (Enum == 1) then
											for Idx = Inst[2], Inst[3] do
												Stk[Idx] = nil;
											end
										else
											local A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
									elseif (Enum <= 3) then
										Stk[Inst[2]] = Stk[Inst[3]];
									elseif (Enum == 4) then
										local FlatIdent_A36C = 0;
										local A;
										while true do
											if (FlatIdent_A36C == 0) then
												A = Inst[2];
												Stk[A] = Stk[A]();
												break;
											end
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											local FlatIdent_7F35E = 0;
											while true do
												if (FlatIdent_7F35E == 0) then
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
													break;
												end
											end
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum <= 8) then
									if (Enum <= 6) then
										Stk[Inst[2]] = Upvalues[Inst[3]];
									elseif (Enum > 7) then
										local FlatIdent_A9A3 = 0;
										local B;
										local A;
										while true do
											if (FlatIdent_A9A3 == 3) then
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_A9A3 = 4;
											end
											if (FlatIdent_A9A3 == 6) then
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_A9A3 = 7;
											end
											if (FlatIdent_A9A3 == 4) then
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												FlatIdent_A9A3 = 5;
											end
											if (FlatIdent_A9A3 == 1) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_A9A3 = 2;
											end
											if (FlatIdent_A9A3 == 0) then
												B = nil;
												A = nil;
												Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
												FlatIdent_A9A3 = 1;
											end
											if (FlatIdent_A9A3 == 2) then
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_A9A3 = 3;
											end
											if (FlatIdent_A9A3 == 7) then
												Stk[Inst[2]][Inst[3]] = Inst[4];
												break;
											end
											if (FlatIdent_A9A3 == 5) then
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_A9A3 = 6;
											end
										end
									else
										local FlatIdent_E0D0 = 0;
										local B;
										local A;
										while true do
											if (FlatIdent_E0D0 == 0) then
												B = nil;
												A = nil;
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_E0D0 = 1;
											end
											if (FlatIdent_E0D0 == 2) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_E0D0 = 3;
											end
											if (FlatIdent_E0D0 == 3) then
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												FlatIdent_E0D0 = 4;
											end
											if (FlatIdent_E0D0 == 6) then
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												break;
											end
											if (FlatIdent_E0D0 == 1) then
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												FlatIdent_E0D0 = 2;
											end
											if (FlatIdent_E0D0 == 4) then
												Inst = Instr[VIP];
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												FlatIdent_E0D0 = 5;
											end
											if (FlatIdent_E0D0 == 5) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_E0D0 = 6;
											end
										end
									end
								elseif (Enum <= 10) then
									if (Enum > 9) then
										local FlatIdent_9622C = 0;
										local A;
										while true do
											if (FlatIdent_9622C == 0) then
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												break;
											end
										end
									else
										local B;
										local A;
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
								elseif (Enum > 11) then
									local B;
									local A;
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
								else
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								end
							elseif (Enum <= 19) then
								if (Enum <= 15) then
									if (Enum <= 13) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											local FlatIdent_2D88C = 0;
											while true do
												if (FlatIdent_2D88C == 0) then
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
													break;
												end
											end
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									elseif (Enum == 14) then
										local A = Inst[2];
										local T = Stk[A];
										local B = Inst[3];
										for Idx = 1, B do
											T[Idx] = Stk[A + Idx];
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											local FlatIdent_D79D = 0;
											while true do
												if (0 == FlatIdent_D79D) then
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
													break;
												end
											end
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum <= 17) then
									if (Enum > 16) then
										Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
									else
										local FlatIdent_40B41 = 0;
										while true do
											if (1 == FlatIdent_40B41) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												FlatIdent_40B41 = 2;
											end
											if (3 == FlatIdent_40B41) then
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												FlatIdent_40B41 = 4;
											end
											if (0 == FlatIdent_40B41) then
												Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												FlatIdent_40B41 = 1;
											end
											if (2 == FlatIdent_40B41) then
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_40B41 = 3;
											end
											if (FlatIdent_40B41 == 5) then
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_40B41 = 6;
											end
											if (FlatIdent_40B41 == 6) then
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = {};
												break;
											end
											if (FlatIdent_40B41 == 4) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]][Inst[3]] = Inst[4];
												VIP = VIP + 1;
												FlatIdent_40B41 = 5;
											end
										end
									end
								elseif (Enum > 18) then
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 22) then
								if (Enum <= 20) then
									local B;
									local A;
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
								elseif (Enum > 21) then
									local A;
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 24) then
								if (Enum == 23) then
									do
										return;
									end
								else
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum == 25) then
								local FlatIdent_2388 = 0;
								local B;
								local A;
								while true do
									if (FlatIdent_2388 == 5) then
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_2388 = 6;
									end
									if (FlatIdent_2388 == 2) then
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_2388 = 3;
									end
									if (4 == FlatIdent_2388) then
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										FlatIdent_2388 = 5;
									end
									if (FlatIdent_2388 == 1) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										FlatIdent_2388 = 2;
									end
									if (FlatIdent_2388 == 6) then
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_2388 = 7;
									end
									if (FlatIdent_2388 == 0) then
										B = nil;
										A = nil;
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										FlatIdent_2388 = 1;
									end
									if (3 == FlatIdent_2388) then
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_2388 = 4;
									end
									if (FlatIdent_2388 == 7) then
										Stk[Inst[2]][Inst[3]] = Inst[4];
										break;
									end
								end
							else
								local B;
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 39) then
							if (Enum <= 32) then
								if (Enum <= 29) then
									if (Enum <= 27) then
										Stk[Inst[2]] = Inst[3] ~= 0;
									elseif (Enum == 28) then
										local FlatIdent_5EE26 = 0;
										local B;
										local A;
										while true do
											if (FlatIdent_5EE26 == 5) then
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_5EE26 = 6;
											end
											if (FlatIdent_5EE26 == 7) then
												Stk[Inst[2]][Inst[3]] = Inst[4];
												break;
											end
											if (FlatIdent_5EE26 == 1) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_5EE26 = 2;
											end
											if (FlatIdent_5EE26 == 4) then
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												FlatIdent_5EE26 = 5;
											end
											if (FlatIdent_5EE26 == 6) then
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_5EE26 = 7;
											end
											if (FlatIdent_5EE26 == 0) then
												B = nil;
												A = nil;
												Stk[Inst[2]] = Inst[3];
												FlatIdent_5EE26 = 1;
											end
											if (FlatIdent_5EE26 == 3) then
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_5EE26 = 4;
											end
											if (FlatIdent_5EE26 == 2) then
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_5EE26 = 3;
											end
										end
									else
										local FlatIdent_40070 = 0;
										local A;
										while true do
											if (FlatIdent_40070 == 0) then
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
												break;
											end
										end
									end
								elseif (Enum <= 30) then
									local Edx;
									local Results, Limit;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										local FlatIdent_86900 = 0;
										while true do
											if (FlatIdent_86900 == 0) then
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
												break;
											end
										end
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
								elseif (Enum > 31) then
									local T;
									local B;
									local A;
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									T = Stk[A];
									B = Inst[3];
									for Idx = 1, B do
										T[Idx] = Stk[A + Idx];
									end
								else
									VIP = Inst[3];
								end
							elseif (Enum <= 35) then
								if (Enum <= 33) then
									Stk[Inst[2]] = Inst[3];
								elseif (Enum == 34) then
									local A = Inst[2];
									Stk[A](Stk[A + 1]);
								else
									local FlatIdent_81225 = 0;
									local Edx;
									local Results;
									local Limit;
									local A;
									while true do
										if (FlatIdent_81225 == 2) then
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 3;
										end
										if (FlatIdent_81225 == 10) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 11;
										end
										if (FlatIdent_81225 == 1) then
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 2;
										end
										if (FlatIdent_81225 == 5) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 6;
										end
										if (FlatIdent_81225 == 0) then
											Edx = nil;
											Results, Limit = nil;
											A = nil;
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 1;
										end
										if (FlatIdent_81225 == 8) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 9;
										end
										if (FlatIdent_81225 == 3) then
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 4;
										end
										if (FlatIdent_81225 == 9) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 10;
										end
										if (FlatIdent_81225 == 7) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 8;
										end
										if (6 == FlatIdent_81225) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 7;
										end
										if (FlatIdent_81225 == 4) then
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_81225 = 5;
										end
										if (13 == FlatIdent_81225) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return;
											end
											break;
										end
										if (FlatIdent_81225 == 11) then
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											FlatIdent_81225 = 12;
										end
										if (FlatIdent_81225 == 12) then
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											FlatIdent_81225 = 13;
										end
									end
								end
							elseif (Enum <= 37) then
								if (Enum > 36) then
									local FlatIdent_8FBAE = 0;
									local NewProto;
									local NewUvals;
									local Indexes;
									while true do
										if (FlatIdent_8FBAE == 0) then
											NewProto = Proto[Inst[3]];
											NewUvals = nil;
											FlatIdent_8FBAE = 1;
										end
										if (FlatIdent_8FBAE == 1) then
											Indexes = {};
											NewUvals = Setmetatable({}, {__index=function(_, Key)
												local Val = Indexes[Key];
												return Val[1][Val[2]];
											end,__newindex=function(_, Key, Value)
												local Val = Indexes[Key];
												Val[1][Val[2]] = Value;
											end});
											FlatIdent_8FBAE = 2;
										end
										if (FlatIdent_8FBAE == 2) then
											for Idx = 1, Inst[4] do
												local FlatIdent_7126B = 0;
												local Mvm;
												while true do
													if (0 == FlatIdent_7126B) then
														VIP = VIP + 1;
														Mvm = Instr[VIP];
														FlatIdent_7126B = 1;
													end
													if (FlatIdent_7126B == 1) then
														if (Mvm[1] == 3) then
															Indexes[Idx - 1] = {Stk,Mvm[3]};
														else
															Indexes[Idx - 1] = {Upvalues,Mvm[3]};
														end
														Lupvals[#Lupvals + 1] = Indexes;
														break;
													end
												end
											end
											Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
											break;
										end
									end
								else
									Stk[Inst[2]] = {};
								end
							elseif (Enum > 38) then
								local B;
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							else
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 46) then
							if (Enum <= 42) then
								if (Enum <= 40) then
									local FlatIdent_21CA5 = 0;
									local Edx;
									local Results;
									local Limit;
									local A;
									while true do
										if (FlatIdent_21CA5 == 10) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 11;
										end
										if (FlatIdent_21CA5 == 8) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 9;
										end
										if (FlatIdent_21CA5 == 13) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return;
											end
											break;
										end
										if (FlatIdent_21CA5 == 4) then
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 5;
										end
										if (2 == FlatIdent_21CA5) then
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 3;
										end
										if (FlatIdent_21CA5 == 1) then
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 2;
										end
										if (9 == FlatIdent_21CA5) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 10;
										end
										if (FlatIdent_21CA5 == 5) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 6;
										end
										if (FlatIdent_21CA5 == 3) then
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 4;
										end
										if (FlatIdent_21CA5 == 6) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 7;
										end
										if (FlatIdent_21CA5 == 11) then
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											FlatIdent_21CA5 = 12;
										end
										if (FlatIdent_21CA5 == 7) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 8;
										end
										if (FlatIdent_21CA5 == 12) then
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											FlatIdent_21CA5 = 13;
										end
										if (0 == FlatIdent_21CA5) then
											Edx = nil;
											Results, Limit = nil;
											A = nil;
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_21CA5 = 1;
										end
									end
								elseif (Enum == 41) then
									local FlatIdent_C595 = 0;
									local B;
									local A;
									while true do
										if (FlatIdent_C595 == 5) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_C595 = 6;
										end
										if (FlatIdent_C595 == 2) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_C595 = 3;
										end
										if (FlatIdent_C595 == 1) then
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											FlatIdent_C595 = 2;
										end
										if (FlatIdent_C595 == 3) then
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											FlatIdent_C595 = 4;
										end
										if (FlatIdent_C595 == 6) then
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_C595 = 7;
										end
										if (FlatIdent_C595 == 7) then
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											break;
										end
										if (FlatIdent_C595 == 4) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											FlatIdent_C595 = 5;
										end
										if (0 == FlatIdent_C595) then
											B = nil;
											A = nil;
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											FlatIdent_C595 = 1;
										end
									end
								else
									Stk[Inst[2]] = Env[Inst[3]];
								end
							elseif (Enum <= 44) then
								if (Enum == 43) then
									local A = Inst[2];
									local T = Stk[A];
									for Idx = A + 1, Inst[3] do
										Insert(T, Stk[Idx]);
									end
								else
									local FlatIdent_98327 = 0;
									local B;
									local A;
									while true do
										if (FlatIdent_98327 == 3) then
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											FlatIdent_98327 = 4;
										end
										if (FlatIdent_98327 == 2) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											FlatIdent_98327 = 3;
										end
										if (FlatIdent_98327 == 4) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											FlatIdent_98327 = 5;
										end
										if (FlatIdent_98327 == 1) then
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											FlatIdent_98327 = 2;
										end
										if (0 == FlatIdent_98327) then
											B = nil;
											A = nil;
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_98327 = 1;
										end
										if (FlatIdent_98327 == 6) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											break;
										end
										if (FlatIdent_98327 == 5) then
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_98327 = 6;
										end
									end
								end
							elseif (Enum == 45) then
								if (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								Stk[Inst[2]][Inst[3]] = Inst[4];
							end
						elseif (Enum <= 49) then
							if (Enum <= 47) then
								local B;
								local A;
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
							elseif (Enum == 48) then
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							else
								local FlatIdent_75331 = 0;
								local A;
								local Results;
								local Limit;
								local Edx;
								while true do
									if (FlatIdent_75331 == 2) then
										for Idx = A, Top do
											local FlatIdent_84478 = 0;
											while true do
												if (FlatIdent_84478 == 0) then
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
													break;
												end
											end
										end
										break;
									end
									if (FlatIdent_75331 == 1) then
										Top = (Limit + A) - 1;
										Edx = 0;
										FlatIdent_75331 = 2;
									end
									if (FlatIdent_75331 == 0) then
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										FlatIdent_75331 = 1;
									end
								end
							end
						elseif (Enum <= 51) then
							if (Enum == 50) then
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							else
								local FlatIdent_2C7C4 = 0;
								local B;
								local A;
								while true do
									if (FlatIdent_2C7C4 == 3) then
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										FlatIdent_2C7C4 = 4;
									end
									if (FlatIdent_2C7C4 == 4) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										FlatIdent_2C7C4 = 5;
									end
									if (FlatIdent_2C7C4 == 1) then
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										FlatIdent_2C7C4 = 2;
									end
									if (FlatIdent_2C7C4 == 5) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
										break;
									end
									if (FlatIdent_2C7C4 == 2) then
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_2C7C4 = 3;
									end
									if (FlatIdent_2C7C4 == 0) then
										B = nil;
										A = nil;
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										FlatIdent_2C7C4 = 1;
									end
								end
							end
						elseif (Enum > 52) then
							local FlatIdent_810B1 = 0;
							local A;
							while true do
								if (FlatIdent_810B1 == 2) then
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									FlatIdent_810B1 = 3;
								end
								if (FlatIdent_810B1 == 1) then
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									FlatIdent_810B1 = 2;
								end
								if (FlatIdent_810B1 == 3) then
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									break;
								end
								if (FlatIdent_810B1 == 0) then
									A = nil;
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									FlatIdent_810B1 = 1;
								end
							end
						else
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
						end
						VIP = VIP + 1;
						break;
					end
					if (FlatIdent_1076E == 0) then
						Inst = Instr[VIP];
						Enum = Inst[1];
						FlatIdent_1076E = 1;
					end
				end
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!573O00028O00027O0040030C3O0043726561746542752O746F6E03043O004E616D65030F3O004265636F6D65204372696D696E616C03083O0043612O6C6261636B030C3O00437265617465546F2O676C65030D3O00496E66696E697465204A756D70030C3O0043752O72656E7456616C7565010003043O00466C616703073O00546F2O676C653103093O0043726561746554616203043O0047756E73022O00A0E9AAB3F041026O000840030A3O006C6F6164737472696E6703043O0067616D6503073O00482O7470476574031C3O00682O7470733A2O2F7369726975732E6D656E752F7261796669656C64030C3O0043726561746557696E646F77030B3O004372797374616C20487562030C3O004C6F6164696E675469746C6503193O004372797374616C20487562202D20507269736F6E204C696665030F3O004C6F6164696E675375627469746C65031B3O006279204074306B796F647231662O74206F6E20646973636F72642E03133O00436F6E66696775726174696F6E536176696E6703073O00456E61626C65642O01030A3O00466F6C6465724E616D65030A3O004372797374616C48756203083O0046696C654E616D65030C3O004372797374616C487562776103073O00446973636F726403063O00496E76697465030C3O006E6F696E766974656C696E6B030D3O0052656D656D6265724A6F696E7303093O004B657953797374656D030B3O004B657953652O74696E677303053O005469746C6503083O005375627469746C65030A3O004B65792053797374656D03043O004E6F746503193O004A6F696E20646973636F726420666F7220746865206B65792E2O033O004B657903073O00536176654B6579030F3O00477261624B657946726F6D53697465030C3O004372797374616C2D3036323503063O004E6F7469667903073O004D652O7361676503073O00436F6E74656E7403223O004173206F66206E6F772C204372797374616C2048756220697320696E20424554412E03083O004475726174696F6E026O001A4003053O00496D61676503073O00416374696F6E7303063O0049676E6F7265030B3O00556E64657273742O6F6421026O00F03F026O001840030D3O0044657374726F7920442O6F727303113O004C6F6164436F6E66696775726174696F6E026O00104003023O004D3903193O004D344131205B47616D6570612O73205265717569726564215D03083O00436F7374756D6573026O00144003043O004D61696E030C3O00437265617465536C6964657203093O0057616C6B53702O656403053O0052616E6765026O003040025O00407F4003093O00496E6372656D656E7403063O0053752O666978030B3O0057616C6B53702O6564463103093O004A756D70506F776572026O004940025O00708740030B3O004A756D70506F776572463103213O005377617420436F7374756D65205B47616D6570612O73205265717569726564215D030E3O00506F6C69636520436F7374756D65030B3O004465737472756374696F6E030D3O0043726561746553656374696F6E033B3O00596F75206D757374206571756970207468652067756E7320796F75722073656C662E2054686973206F6E6C792074656C65706F72747320796F752E030D3O0052656D696E67746F6E2038373003053O00414B2D343700C93O0012213O00014O0001000100073O00262D3O001A0001000200041F3O001A00010020320008000300032O0024000A3O000200302E000A00040005000211000B5O00100C000A0006000B4O0008000A00024O000500083O00202O0008000300074O000A3O000400302O000A0004000800302O000A0009000A00302O000A000B000C000211000B00013O00102C000A0006000B4O0008000A00024O000600083O00202O00080002000D00122O000A000E3O00122O000B000F6O0008000B00024O000300083O00124O00103O00262D3O00520001000100041F3O0052000100122A000800113O00121E000900123O00202O00090009001300122O000B00146O0009000B6O00083O00024O0008000100024O000100083O00202O0008000100154O000A3O000700302O000A0004001600302E000A00170018003034000A0019001A4O000B3O000300302O000B001C001D00122O000C001F3O00102O000B001E000C00302O000B0020002100102O000A001B000B4O000B3O000300302O000B001C000A00302O000B0023002400302E000B0025001D002O10000A0022000B00302O000A0026000A4O000B3O000700302O000B0028001600302O000B0029002A00302O000B002B002C00302O000B0020002D00302O000B002E001D00302O000B002F000A4O000C00013O001221000D00304O000E000C0001000100100B000B002D000C00100C000A0027000B4O0008000A00024O000200083O00202O0008000100314O000A3O000500302O000A0028003200302O000A0033003400302O000A0035003600302E000A0037000F2O0024000B3O00012O0024000C3O000200302E000C0004003A000211000D00023O001035000C0006000D00102O000B0039000C00102O000A0038000B4O0008000A000100124O003B3O00262D3O005E0001003C00041F3O005E00010020320008000300032O0024000A3O000200302E000A0004003D000211000B00033O001033000A0006000B4O0008000A00024O000500083O00202O00080001003E4O00080002000100044O00C8000100262D3O00740001003F00041F3O007400010020320008000300032O0024000A3O000200302E000A00040040000211000B00043O00102F000A0006000B4O0008000A00024O000500083O00202O0008000300034O000A3O000200302O000A00040041000211000B00053O00102C000A0006000B4O0008000A00024O000500083O00202O00080002000D00122O000A00423O00122O000B000F6O0008000B00024O000300083O00124O00433O00262D3O009C0001003B00041F3O009C000100203200080002000D001207000A00443O00122O000B000F6O0008000B00024O000300083O00202O0008000300454O000A3O000700302O000A000400464O000B00023O00122O000C00483O00122O000D00494O000E000B0002000100100B000A0047000B00302E000A004A003B00302E000A004B004600302E000A0009004800302E000A000B004C000211000B00063O00102F000A0006000B4O0008000A00024O000400083O00202O0008000300454O000A3O000700302O000A0004004D2O0024000B00023O001221000C004E3O001221000D004F4O000E000B0002000100100B000A0047000B00302E000A004A003B00302E000A004B004D00302E000A0009004E00302E000A000B0050000211000B00073O00100B000A0006000B2O000A0008000A00022O0003000400083O0012213O00023O00262D3O00B20001004300041F3O00B200010020320008000300032O0024000A3O000200302E000A00040051000211000B00083O00102F000A0006000B4O0008000A00024O000500083O00202O0008000300034O000A3O000200302O000A00040052000211000B00093O00102C000A0006000B4O0008000A00024O000500083O00202O00080002000D00122O000A00533O00122O000B000F6O0008000B00024O000300083O00124O003C3O00262D3O00020001001000041F3O0002000100203200080003005400121C000A00556O0008000A00024O000700083O00202O0008000300034O000A3O000200302O000A00040056000211000B000A3O00102F000A0006000B4O0008000A00024O000500083O00202O0008000300034O000A3O000200302O000A00040057000211000B000B3O001016000A0006000B4O0008000A00024O000500083O00124O003F3O00044O000200012O00173O00013O000C3O000F3O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F723302C87C40A0B3CD8BC0027715527E52C15C4002D5CA845FCA27A040028O00026O00F03F03023O002D30026O00F0BF00193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000C3O00122O0008000D3O00122O0009000C3O00122O000A000D3O00122O000B000E3O00122O000C000F3O00122O000D000C3O00122O000E000C6O0002000E6O00013O000200104O000600016O00017O00063O00028O0003043O0067616D65030A3O004765745365727669636503103O0055736572496E70757453657276696365030B3O004A756D705265717565737403073O00636F2O6E65637401113O001221000100014O0001000200023O00262D000100020001000100041F3O000200012O001B000200013O001227000300023O00202O00030003000300122O000500046O00030005000200202O00030003000500202O00030003000600062500053O000100012O00033O00024O000200030005000100041F3O0010000100041F3O000200012O00173O00013O00013O00093O0003043O0067616D65030A3O004765745365727669636503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203153O0046696E6446697273744368696C644F66436C612O7303083O0048756D616E6F6964030B3O004368616E6765537461746503073O004A756D70696E6700104O00067O0006133O000F00013O00041F3O000F000100122A3O00013O0020095O000200122O000200038O0002000200206O000400206O000500206O000600122O000200078O0002000200206O000800122O000200098O000200012O00173O00017O00023O0003053O007072696E7403173O0057656C636F6D6520746F204372797374616C204875622100043O00122A3O00013O001221000100024O00223O000200012O00173O00017O00043O0003043O0067616D6503093O00576F726B737061636503053O00442O6F727303073O0044657374726F7900063O00121A3O00013O00206O000200206O000300206O00046O000200016O00017O00113O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F7233025B7C0A805198894002594FADBEBA9E5940020A4B3CA0BC94A140025O00F0003F029BD0F1BFFFA0E63F02F3D6F6FF3CA0E6BF025O0010ECBE02F3D6F6FF3CA0E63F026O00F03F00193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000D3O00122O0008000E3O00122O0009000F3O00122O000A00103O00122O000B000D3O00122O000C00113O00122O000D000F3O00122O000E000C6O0002000E6O00013O000200104O000600016O00017O000E3O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F72330229232E004DAE8A4002F8C3CF7F0F015A40029F5912A0F694A140026O00F0BF028O00026O00F03F00193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000D3O00122O0008000D3O00122O0009000D3O00122O000A000E3O00122O000B000D3O00122O000C000D3O00122O000D000D3O00122O000E000C6O0002000E6O00013O000200104O000600016O00017O00063O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203083O0048756D616E6F696403093O0057616C6B53702O656401073O001226000100013O00202O00010001000200202O00010001000300202O00010001000400202O00010001000500102O000100068O00017O00063O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203083O0048756D616E6F696403093O004A756D70506F77657201073O001226000100013O00202O00010001000200202O00010001000300202O00010001000400202O00010001000500102O000100068O00017O000E3O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F72330229232E004DAE8A4002F8C3CF7F0F015A40029F5912A0F694A140026O00F0BF028O00026O00F03F00193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000D3O00122O0008000D3O00122O0009000D3O00122O000A000E3O00122O000B000D3O00122O000C000D3O00122O000D000D3O00122O000E000C6O0002000E6O00013O000200104O000600016O00017O00113O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F7233025B7C0A805198894002594FADBEBA9E5940020A4B3CA0BC94A140025O00F0003F029BD0F1BFFFA0E63F02F3D6F6FF3CA0E6BF025O0010ECBE02F3D6F6FF3CA0E63F026O00F03F00193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000D3O00122O0008000E3O00122O0009000F3O00122O000A00103O00122O000B000D3O00122O000C00113O00122O000D000F3O00122O000E000C6O0002000E6O00013O000200104O000600016O00017O000F3O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F7233026ADFDC5FBDAC8DC00286151340D66757400244DD0720350FA040028O00026O00F0BF026O00F03F03023O002D3000193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000D3O00122O0008000C3O00122O0009000E3O00122O000A000C3O00122O000B000F3O00122O000C000C3O00122O000D000C3O00122O000E000E6O0002000E6O00013O000200104O000600016O00017O000E3O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D652O033O006E657703073O00566563746F723302041BD7BF8B498DC002FDB50600586757400241D47D004210A040028O00026O00F03F026O00F0BF00193O00120D3O00013O00206O000200206O000300206O000400206O000500122O000100063O00202O00010001000700122O000200083O00202O00020002000700122O000300093O00122O0004000A3O00122O0005000B3O00122O0006000C3O00122O0007000C3O00122O0008000D3O00122O0009000E3O00122O000A000C3O00122O000B000C3O00122O000C000C3O00122O000D000E3O00122O000E000C6O0002000E6O00013O000200104O000600016O00017O00", GetFEnv(), ...);