----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:00:29 12/14/2015 
-- Design Name: 
-- Module Name:    RAM-IDE-AUTOCONFIG - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM_IDE_AUTOCONFIG is
    Port ( A : in  STD_LOGIC_VECTOR (23 downto 1);
           D : inout  STD_LOGIC_VECTOR (15 downto 0);
           AS : in  STD_LOGIC;
           DTACK : out  STD_LOGIC;
           RW : in  STD_LOGIC;
           UDS : in  STD_LOGIC;
           LDS : in  STD_LOGIC;
           BERR : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
           C1 : in  STD_LOGIC;
           C3 : in  STD_LOGIC;
           CDAC : in  STD_LOGIC;
           ARAM : out  STD_LOGIC_VECTOR (11 downto 0);
           DRAM : inout  STD_LOGIC_VECTOR (15 downto 0);
           BA : out  STD_LOGIC_VECTOR (1 downto 0);
           LDQM : out  STD_LOGIC;
           UDQM : out  STD_LOGIC;
           CKE : out  STD_LOGIC;
           CLK_MEM : out  STD_LOGIC;
           MEM_WE : out  STD_LOGIC;
           CAS : out  STD_LOGIC;
           RAS : out  STD_LOGIC;
           MEM_CS : out  STD_LOGIC;
           IDE_A : out  STD_LOGIC_VECTOR (2 downto 0);
           IDE_CS : out  STD_LOGIC_VECTOR (1 downto 0);
           IDE_W : out  STD_LOGIC;
           IDE_R : out  STD_LOGIC;
           IDE_WAIT : in  STD_LOGIC;
           IDE_IRQ : in  STD_LOGIC;
           ROM_BANK : out  STD_LOGIC_VECTOR (3 downto 0);
           ROM_OE : out  STD_LOGIC;
           ROM_WE : out  STD_LOGIC;
           MEM_OFF : in  STD_LOGIC;
           IDE_OFF : in  STD_LOGIC;
			  CF_IN : in  STD_LOGIC;
           CF_OUT : out  STD_LOGIC;
           CLK50M : in  STD_LOGIC
			  );
end RAM_IDE_AUTOCONFIG;

architecture Behavioral of RAM_IDE_AUTOCONFIG is
	SIGNAL ide: STD_LOGIC:= '0';
	SIGNAL ram: STD_LOGIC:= '0';
	SIGNAL autoconfig: STD_LOGIC:= '0';
	signal Dout:STD_LOGIC_VECTOR(3 downto 0);
	signal AUTO_CONFIG_DONE:STD_LOGIC_VECTOR(1 downto 0);
	signal AUTO_CONFIG_DONE_CYCLE:STD_LOGIC_VECTOR(1 downto 0);
	signal SHUT_UP:STD_LOGIC_VECTOR(1 downto 0);
	signal IDE_BASEADR:STD_LOGIC_VECTOR(7 downto 0);
	signal IDE_ENABLE:STD_LOGIC:= '0';
	signal ROM_OE_S:STD_LOGIC:= '1';
	signal IDE_R_S:STD_LOGIC:= '1';
	signal IDE_W_S:STD_LOGIC:= '1';
	signal TRANSFER_IN_PROGRES:STD_LOGIC:= '1';
	signal AUTOCONFIG_IN_PROGRES:STD_LOGIC:= '1';
   signal AS_D: std_logic:= '1';
	signal REFRESH: std_logic:= '1';
	signal CLRREFC: std_logic:= '1';
	Signal TRANSFER: std_logic:= '1';

	TYPE sdram_state_machine_type IS (
				powerup, 					--000000
				init_precharge,			--000001 
				init_precharge_commit,  --000011
				init_opcode,				--000111
				init_opcode_wait,			--000111
				init_refresh,				--000010
				init_wait,					--000110
				start_state,				--000100
				refresh_start,				--001100
				refresh_wait,				--001101
				start_ras,			--001111
				commit_ras,			--001110
				start_cas,			--001010
				commit_cas,			--001011
				data_wait,			--001001
				precharge,			--110011
				precharge_wait			--001001
				);
	TYPE sdram_control IS (
				c_nop,
				c_ras,
				c_cas,
				c_precharge,
				c_refresh,
				c_opt_code
	);
	signal CLK_A_D0 :  std_logic;
	signal CLK_A_D1 :  std_logic;
	signal NQ :  STD_LOGIC_VECTOR (1 downto 0);
	signal RQ :  STD_LOGIC_VECTOR (3 downto 0);
	signal CQ :  sdram_state_machine_type;
	signal CQ_D :  sdram_state_machine_type;
	signal SDRAM_OP :  sdram_control;
   signal RAM_D: STD_LOGIC_VECTOR (15 downto 0);      
   signal ARAM_LOW: STD_LOGIC_VECTOR (11 downto 0);      
   signal ARAM_HIGH: STD_LOGIC_VECTOR (11 downto 0);      
   signal ARAM_PRECHARGE: STD_LOGIC_VECTOR (11 downto 0);   
   signal ARAM_OPTCODE: STD_LOGIC_VECTOR (11 downto 0);   
	signal DS : STD_LOGIC;

   Function to_std_logic(X: in Boolean) return Std_Logic is
   variable ret : std_logic;
   begin
   if x then ret := '1';  else ret := '0'; end if;
   return ret;
   end to_std_logic;
	
begin

	
	ADDRESS_DECODE: process(reset, CLK50M)
	begin
		if	reset = '0' then
			-- reset active ...
			autoconfig	<= '0';
			ide <='0';
			ram <='0';
			TRANSFER_IN_PROGRES <= '0';
			AUTOCONFIG_IN_PROGRES <= '0';
			AS_D <='1';
			DS	<= '0';
		elsif(rising_edge(CLK50M))then
			AS_D <= AS;

			if(AS_D='1') then
				TRANSFER_IN_PROGRES <= '0';
				AUTOCONFIG_IN_PROGRES <= '0';
			elsif(AS_D='0') then
				TRANSFER_IN_PROGRES <= ram;
				AUTOCONFIG_IN_PROGRES <= autoconfig;
			end if;

			if(UDS='0' or LDS ='0')then
				DS <= '1';
			else
				DS	<= '0';
			end if;


			if(A(23 downto 16) = x"E8" and CF_IN='0' and (AUTO_CONFIG_DONE(0)='0' or  AUTO_CONFIG_DONE(1)='0') )then
				autoconfig <='1';
			else
				autoconfig <='0';
			end if;

			if(A(23 downto 16) = IDE_BASEADR and SHUT_UP(1) = '0')then					
				ide <='1';					
			else
				ide <='0';
			end if;
			
			if(SHUT_UP(0)  = '0' 
				and(
				A(23 downto 21) = "001" 
				or A(23 downto 21) = "010" 
				or A(23 downto 21) = "011" 
				or A(23 downto 21) = "100") )then
				ram <='1';
			else
				ram <='0';
			end if;
				
		end if;				
	end process ADDRESS_DECODE;
	
	--ide
		-- this is the clocked process
	ide_rw_gen: process (reset,CLK50M)
	begin
	
		if	(reset = '0') then
				IDE_R_S		<= '1';
				IDE_W_S		<= '1';
				ROM_OE_S		<= '1';
				IDE_ENABLE 	<= '1';
		elsif rising_edge(CLK50M) then
			if(AS='0' and ide='1')then
				if(RW='0')then
					--the write goes to the hdd!
					IDE_ENABLE  <= '0'; -- enable IDE on first read
					IDE_W_S		<= '0';	
					IDE_R_S		<= '1';
					ROM_OE_S		<=	'1';
				else
					IDE_W_S		<= '1';						
					IDE_R_S		<= IDE_ENABLE; --read from IDE instead from ROM
					ROM_OE_S		<=	not IDE_ENABLE;						
				end if;	
			else
				IDE_R_S		<= '1';
				IDE_W_S		<= '1';
				ROM_OE_S		<= '1';					
			end if;			
		end if;
	end process ide_rw_gen;
		
	
	--autoconfig
	CF_OUT <= '0' when AUTO_CONFIG_DONE ="11" else '1';
	autoconfig_done: process (reset, AS_D)
	begin
		if	reset = '0' then
			-- reset active ...
			AUTO_CONFIG_DONE	<="00";			
		elsif rising_edge(AS_D) then -- no reset, so wait for rising edge of the nAS
			if(MEM_OFF = '1') then
				AUTO_CONFIG_DONE <= AUTO_CONFIG_DONE or AUTO_CONFIG_DONE_CYCLE(1) & '1';
			else
				AUTO_CONFIG_DONE <= AUTO_CONFIG_DONE or AUTO_CONFIG_DONE_CYCLE;
			end if;
		end if;
	end process autoconfig_done;


	autoconfig_proc: process (reset, CLK50M)
	begin
		if	reset = '0' then
				-- reset active ...
				AUTO_CONFIG_DONE_CYCLE	<="00";
				Dout<="1111";
				SHUT_UP	<="11";
				IDE_BASEADR<=x"FF";
		elsif rising_edge(CLK50M) then -- no reset, so wait for rising edge of the clock		
			
			if(AUTO_CONFIG_DONE(0)='0')then
				case A(6 downto 1) is
					when "000000"	=> 
						Dout <= 	"1110" ; --ZII, System-Memory, no ROM
					when "000001"	=> Dout <=	"0000" ; --one Card, 4MB = 111
					--when "0000100"	=> Dout <=	"1111" ; --ProductID high nibble : E->0001
					when "000011"	=> Dout <=	"1101" ; --ProductID low nibble: F->0000
					--when "0001000"	=> Dout <=	"1111" ; --Config HIGH: 0x20 and no shut down
					--when "0001010"	=> Dout <=	"1111" ; --Config LOW
					--when "0010000"	=> Dout <=	"1111" ; --Ventor ID 0
					when "001001"	=> Dout <=	"0101" ; --Ventor ID 1
					when "001010"	=> Dout <=	"1110" ; --Ventor ID 2
					when "001011"	=> Dout <=	"0011" ; --Ventor ID 3 : $0A1C: A1K.org
					--when "0011000"	=> Dout <=	"1111" ; --Serial byte 0 (msb) high nibble
					--when "0011010"	=> Dout <=	"1111" ; --Serial byte 0 (msb) low  nibble
					--when "0011100"	=> Dout <=	"1111" ; --Serial byte 1       high nibble
					--when "0011110"	=> Dout <=	"1111" ; --Serial byte 1       low  nibble
					--when "0100000"	=> Dout <=	"1111" ; --Serial byte 2       high nibble
					--when "0100010"	=> Dout <=	"1111" ; --Serial byte 2       low  nibble
					--when "0100100"	=> Dout <=	"1111" ; --Serial byte 3 (lsb) high nibble
					when "010011"	=> Dout <=	"1110" ; --Serial byte 3 (lsb) low  nibble
					when "100000"	=> Dout <=	"0000" ; --Interrupt config: all zero
					when "100001"	=> Dout <=	"0000" ; --Interrupt config: all zero
					when others	=> Dout <=	"1111" ;
				end case;
			else	
				case A(6 downto 1) is
					when "000000"	=> 
						Dout <= 	"1101" ; --ZII, no System-Memory, ROM
					when "000001"	=> Dout <=	"0001" ; --one Card, 64kb = 001
					--when "0000100"	=> Dout <=	"1111" ; --ProductID high nibble : F->0000=0
					when "000011"	=> Dout <=	"1001" ; --ProductID low nibble: 9->0110=6
					--when "0001000"	=>                                                                                                                                                                                                                                                                                                                        Dout <=	"1111" ; --Config HIGH: 0x20 and no shut down
					--when "0001010"	=> Dout <=	"1111" ; --Config LOW
					--when "0010000"	=> Dout <=	"1111" ; --Ventor ID 0
					when "001001"	=> Dout <=	"0111" ; --Ventor ID 1
					when "001010"	=> Dout <=	"1101" ; --Ventor ID 2
					when "001011"	=> Dout <=	"0011" ; --Ventor ID 3 : $082C: BSC
					when "001100"	=> Dout <=	"0100" ; --Serial byte 0 (msb) high nibble
					when "001101"	=> Dout <=	"1110" ; --Serial byte 0 (msb) low  nibble
					when "001110"	=> Dout <=	"1001" ; --Serial byte 1       high nibble
					when "001111"	=> Dout <=	"0100" ; --Serial byte 1       low  nibble
					--when "0100000"	=> Dout <=	"1111" ; --Serial byte 2       high nibble
					--when "0100010"	=> Dout <=	"1111" ; --Serial byte 2       low  nibble
					when "010010"	=> Dout <=	"0100" ; --Serial byte 3 (lsb) high nibble
					when "010011"	=> Dout <=	"1010" ; --Serial byte 3 (lsb) low  nibble: B16B00B5
					--when "0101000"	=> Dout <=	"1111" ; --Rom vector high byte high nibble 
					--when "0101010"	=> Dout <=	"1111" ; --Rom vector high byte low  nibble 
					--when "0101100"	=> Dout <=	"1111" ; --Rom vector low byte high nibble
					when "010111"	=> Dout <=	"1110" ; --Rom vector low byte low  nibble
					when "100000"	=> Dout <=	"0000" ; --Interrupt config: all zero
					when "100001"	=> Dout <=	"0000" ; --Interrupt config: all zero
					when others	=> Dout <=	"1111" ;
				end case;
			end if;
			
			if(autoconfig= '1' and AS_D='0' and AS='0' and RW='0' and UDS='0' )then --write and data valid
				if(AUTO_CONFIG_DONE(0)='0')then
					if(A (6 downto 1)="100100")then								
						AUTO_CONFIG_DONE_CYCLE(0)	<='1'; --done here
						SHUT_UP(0)				<='0'; --enable board
					elsif(A (6 downto 1)="100110")then
						AUTO_CONFIG_DONE_CYCLE(0)	<='1'; --done here
					end if;
				elsif(AUTO_CONFIG_DONE(1)='0')then
					if(A (6 downto 1)="100100")then
						IDE_BASEADR(7 downto 0)	<= D(15 downto 8); --Base adress
						SHUT_UP(1) <= '0'; --enable board
						AUTO_CONFIG_DONE_CYCLE(1)	<='1'; --done here
					elsif(A (6 downto 1)="100110")then
						AUTO_CONFIG_DONE_CYCLE(1)	<='1'; --done here
					end if;
				end if;
			end if;
		end if;
	end process autoconfig_proc; --- that's all

	-- ram register Section

   process (CLK50M) begin
      if rising_edge(CLK50M) then
			if(CLRREFC ='1')then
				REFRESH <= '0';
			elsif(RQ >= "1111") then --15600ns = 111 7Mhz-Clocks = 10111 - 8 clocks safety margin = 10000!
				REFRESH <= '1';
			end if;

			CLK_A_D0 <= CDAC;
			CLK_A_D1 <= CLK_A_D0;
			if CLRREFC='1' then
				RQ<=	"0000";
			elsif(CLK_A_D1='1' and CLK_A_D0 ='0' and RQ <"1111") then --count on falling edges
				RQ <= RQ +1;
			end if;
			
						
			if(
				CQ = init_precharge_commit or
				CQ = init_wait or	
				CQ = init_opcode_wait or
				CQ = refresh_wait)
			then
				if(NQ < "11")then
					NQ <= NQ +1;
				end if;
			else 
				NQ  <= "00";
			end if;
			
			if(	CQ_D = start_cas or
					CQ_D = commit_cas or
					CQ_D = data_wait 
				)then
				 if(RW='1') then
					UDQM <= '0';
					LDQM <= '0';
				 else
					UDQM <= UDS;
					LDQM <= LDS;
				 end if;
			else
					UDQM <= '1';
					LDQM <= '1';
			end if;
			
			
			case SDRAM_OP is
			when c_nop=>
				MEM_CS <= '1';
				MEM_WE <= '1';
				CAS <= '1';
				RAS <= '1';
				ARAM <= "000000000000";
				BA <= A(22 downto 21);
			when c_ras=>
				MEM_CS <= '0';
				MEM_WE <= '1';
				CAS <= '1';
				RAS <= '0';
				ARAM <= ARAM_HIGH;
				BA <= A(22 downto 21);
			when c_cas=>
				MEM_CS <= '0';
				MEM_WE <= RW;
				CAS <= '0';
				RAS <= '1';
				ARAM <= ARAM_LOW;
				BA <= A(22 downto 21);
			when c_precharge=>
				MEM_CS <= '0';
				MEM_WE <= '0';
				CAS <= '1';
				RAS <= '0';
				ARAM <= ARAM_PRECHARGE;
				BA <= A(22 downto 21);
			when c_refresh=>
				MEM_CS <= '0';
				MEM_WE <= '1';
				CAS <= '0';
				RAS <= '0';
				ARAM <= "000000000000";								
				BA <= A(22 downto 21);
			when c_opt_code=>
				MEM_CS <= '0';
				MEM_WE <= '0';
				CAS <= '0';
				RAS <= '0';
				ARAM <= ARAM_OPTCODE;			
				BA <= "00";
			end case;
									
	      if reset='0' then
				CQ	<= powerup;
			else
				CQ	<= CQ_D;
			end if;
		end if;
   end process;

   --process to latch the data from the ram
   process (CLK50M) begin
      if falling_edge(CLK50M) then
			if(  CQ = precharge and RW='1')then
				RAM_D <=DRAM;
			end if;
     end if;
   end process;

	--signal assignment
	D	<=	RAM_D 						when RW='1' and TRANSFER_IN_PROGRES ='1' else
			Dout	& "111111111111" 	when RW='1' and AUTOCONFIG_IN_PROGRES ='1' else
			"ZZZZZZZZZZZZZZZZ";

	DRAM <= 	D when RW='0' and AS ='0' else
				"ZZZZZZZZZZZZZZZZ";
								
	IDE_W <=	IDE_W_S;
	IDE_R <=	IDE_R_S;
	IDE_CS(0)<= not(A(12));			
	IDE_CS(1)<= not(A(13));
	IDE_A(0)	<= A(9);
	IDE_A(1)	<= A(10);
	IDE_A(2)	<= A(11);
	ROM_BANK	<= "0000";
	ROM_WE	<= '1';
	ROM_OE	<= ROM_OE_S when IDE_OFF ='0' else '1';				
	
	DTACK <= 'Z';


	CLRREFC <= '1' when 	CQ = init_refresh or 
								CQ = refresh_start 								
						else '0';


   process (CQ,RESET,TRANSFER_IN_PROGRES) begin
		if(CQ = start_ras or RESET ='0')then
			TRANSFER <= '0';
		elsif rising_edge(TRANSFER_IN_PROGRES) then
			TRANSFER <= '1';
		end if;
	end process;
 
   CLK_MEM <= (not CLK50M);
   CKE <=	'1';

	ARAM_LOW  <=  "0000" & A(8 downto 1);
	ARAM_HIGH <= A(20 downto 9);
	ARAM_PRECHARGE <= "010000000000";
	ARAM_OPTCODE <= "001000100000";
	
	-- ram state machine
   process (DS, CQ, REFRESH, TRANSFER, NQ,AUTO_CONFIG_DONE)
   begin
      
      case CQ is

      when powerup =>	 
		 SDRAM_OP<= c_nop;
		 if(AUTO_CONFIG_DONE(0)='1')then --wait until autoconfig is finished. this makes a nice delay!
			CQ_D <= init_precharge;
		 else
			CQ_D <= powerup;
		 end if;

      when init_precharge =>
		 SDRAM_OP<= c_precharge;
		 CQ_D <= init_precharge_commit;

      when init_precharge_commit =>
		 SDRAM_OP<= c_nop;
		 if (NQ >= "10") then
		    CQ_D <= init_opcode;  
		 else
		    CQ_D <= init_precharge_commit;
		 end if;

      when init_opcode =>
		 SDRAM_OP <= c_opt_code;
		 CQ_D <= init_opcode_wait;

      when init_opcode_wait =>
		 SDRAM_OP<= c_nop;
		 if (NQ >= "10") then
		    CQ_D <= init_refresh;   --1st refresh
		 else
		    CQ_D <= init_opcode_wait;
		 end if;

      when init_refresh =>
		 SDRAM_OP<= c_refresh;
		 CQ_D <= init_wait;

      when init_wait =>
		 SDRAM_OP<= c_nop;
		 if (	NQ >= "10") then    --wait 60ns here
			CQ_D <= refresh_start; --last refresh completes initialzation
		 else
		    CQ_D <= init_wait;
		 end if;

      when start_state =>
		 SDRAM_OP<= c_nop;		 
		 if (TRANSFER = '1') then
		    CQ_D <= start_ras;
		 elsif (REFRESH='1') then
		    CQ_D <= refresh_start;
		 else
		    CQ_D <= start_state;
		 end if;
		 
      when refresh_start =>
		 SDRAM_OP<= c_refresh;
		 CQ_D <= refresh_wait;

      when refresh_wait =>
		 SDRAM_OP<= c_nop;
		 if (NQ >= "10") then			--wait 60ns here
			 if (TRANSFER = '1') then
				CQ_D <= start_ras;
			 else
		      CQ_D <= start_state;
			 end if;
		 else
		    CQ_D <= refresh_wait;
		 end if;

      when start_ras =>
		 SDRAM_OP<= c_ras;
		 CQ_D <= commit_ras;

	  when commit_ras =>
		 SDRAM_OP<= c_nop;
		 if(DS='1')then  --wait here for a valid datastrobe on writes
			CQ_D <= start_cas;
		 else
			CQ_D <= commit_ras;
		 end if;

      when start_cas =>
		 SDRAM_OP<= c_cas;
		 CQ_D <= commit_cas;

      when commit_cas =>
		 SDRAM_OP<= c_nop;
 		 CQ_D <= data_wait;

      when data_wait =>
		 SDRAM_OP<= c_nop;
		 CQ_D <= precharge;

      when precharge =>
		 SDRAM_OP<= c_precharge;
		 CQ_D <= precharge_wait;

      when precharge_wait =>
		 SDRAM_OP<= c_nop;
		 CQ_D <= start_state; 

		end case;
   end process;
end Behavioral;

