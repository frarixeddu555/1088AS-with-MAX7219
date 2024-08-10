--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:58:49 07/29/2024
-- Design Name:   
-- Module Name:   C:/Users/matte/Documents/ISE projects/CNTRL_1088AS_with_MAX7219/tb_CONTROLLER_MAX7219.vhd
-- Project Name:  CNTRL_1088AS_with_MAX7219
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: CONTROLLER_MAX7219
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
 
ENTITY tb_CONTROLLER_MAX7219 IS
END tb_CONTROLLER_MAX7219;
 
ARCHITECTURE behavior OF tb_CONTROLLER_MAX7219 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT CONTROLLER_MAX7219
    PORT(
         ck : IN  std_logic;
         reset : IN  std_logic;
         btn : IN  std_logic;
         data_out : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal ck : std_logic := '0';
   signal reset : std_logic := '0';
   signal btn : std_logic := '0';

 	--Outputs
   signal data_out : std_logic_vector(15 downto 0);
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant ck_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: CONTROLLER_MAX7219 PORT MAP (
          ck => ck,
          reset => reset,
          btn => btn,
          data_out => data_out
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

		btn <= '1';
		
		wait for 30 ns;
		
		btn <= '0';

--      data <= "0101010101010101";
		
--      switch <= "00000001";

      wait for 20 ms;

--      switch <= "00000010";

		reset <= '1';
		
      wait for 100 ns;	
		
		reset <= '0';
		
		wait for 3 ms;
		
		btn <= '1';
		
		wait for 30 ns;
		
		btn <= '0';

      wait;
   end process;

END;
