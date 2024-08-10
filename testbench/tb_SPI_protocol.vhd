--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:07:24 07/18/2024
-- Design Name:   
-- Module Name:   C:/Users/matte/Documents/ISE projects/CNTRL_1088AS_with_MAX7219/tb_SPI_protocol.vhd
-- Project Name:  CNTRL_1088AS_with_MAX7219
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SPI_protocol
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_SPI_protocol IS
END tb_SPI_protocol;
 
ARCHITECTURE behavior OF tb_SPI_protocol IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SPI_protocol
    PORT(
         ck : IN  std_logic;
         reset : IN  std_logic;
--         data : IN  std_logic_vector(15 downto 0);
--			switch : IN std_logic_vector (7 downto 0);
			 start : IN std_logic;
			
         sck : OUT  std_logic;
         s_data : OUT  std_logic;
         cs : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal ck : std_logic := '0';
   signal reset : std_logic := '0';
--   signal data : std_logic_vector(15 downto 0) := (others => '0');
	signal start : std_logic;
--	signal switch : std_logic_vector (7 downto 0);

 	--Outputs
   signal sck : std_logic;
   signal s_data : std_logic;
   signal cs : std_logic;
	
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant ck_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SPI_protocol PORT MAP (
          ck => ck,
          reset => reset,
--          data => data,
			 start => start,
          sck => sck,
          s_data => s_data,
          cs => cs
        );

   -- Clock process definitions
   ck_process :process
   begin
		ck <= '0';
		wait for ck_period/2;
		ck <= '1';
		wait for ck_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      
		reset <= '1';
		
      wait for 100 ns;	
		
		reset <= '0';
		
		wait for 100 ns;

		start <= '1';
		
		wait for 30 ns;
		
		start <= '0';

--      data <= "0101010101010101";
		
--      switch <= "00000001";

      wait for 20 ms;

--      switch <= "00000010";

		reset <= '1';
		
      wait for 100 ns;	
		
		reset <= '0';
		
		wait for 3 ms;
		
		start <= '1';
		
		wait for 30 ns;
		
		start <= '0';


      -- insert stimulus here 

      wait;
   end process;

end;
