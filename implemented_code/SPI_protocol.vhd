-----------------------------------------------------------------------------------------
-- This is a module that realize an SPI protocol to drive MAX7219 driver that drives a 
-- LED matrix 1088AS. 
-- A data of 16 bit is sent through a serial transmission. The communication begin with 
-- the reception of "start" signal that make load the value of "data" in a shift register 
-- and set "cs" signal to zero. The MSB of "data" is provided to the output with the "s_data"
-- signal. "s_data" is read by every rising edge of "sck" signal, then "data" is shifted
-- by an "sh" signal. This is repeatd for 16 bit. Finished them, "cs" need to be setted to 1
-- for a minimum certain period.Then the transmission of another 16 bit data is possible.
-----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_protocol is
    port(
        ck          : in std_logic;                         -- 50 MHz
        reset       : in std_logic;
        start       : in std_logic;
        data         : in std_logic_vector (15 downto 0);   -- received by CONTROLLER_MAX7219

        sck              : out std_logic;                   -- input to MAX7219 device
        s_data           : out std_logic;                   -- input to MAX7219 device
        cs               : out std_logic;                   -- input to MAX7219 device
        hit_seq          : out std_logic                    -- input to CONTROLLER_MAX7219
    );

end SPI_protocol;

architecture Behavioral of SPI_protocol is

signal hit_tcss     : std_logic;
signal en_tcss      : std_logic;

signal count_sck1   : unsigned (24 downto 0);
signal hit_sck1     : std_logic;
signal en_sck1      : std_logic;

signal count_sck0   : unsigned (24 downto 0);
signal hit_sck0     : std_logic;
signal en_sck0      : std_logic;

signal count_16     : unsigned (3 downto 0);
signal hit_16       : std_logic;
signal en_count_16  : std_logic;

signal count_wait_cs    : unsigned (27 downto 0);
signal hit_wait_cs      : std_logic;
signal en_count_wait_cs : std_logic;

signal load_data        : std_logic;
signal sh_data          : std_logic;

signal reg          : unsigned (15 downto 0);

type state_t is (IDLE, LOAD, TCSS, SCK1, SCK0, SHIFT, CHECK_16, WAIT_CS, STORE);
    signal state, state_nxt : state_t;

begin    

-- required wait period between falling edge of negCS and rising edge of SCK 
--(not necessary for MAX7219) 
COUNTER_TCSS : process (ck, reset)    
    begin
        if (reset = '1') then
            hit_tcss <= '0';
        elsif (ck'event and ck = '1') then
            if (en_tcss = '1') then
                hit_tcss <= not hit_tcss;   -- all hit signals make advance the FSM
            end if;
        end if;
    end process;
------------------------------------------------------------------------------------
-- This process manages the duration of the UP and DOWN sck signal.
-- With hit_sck1 and hit_sck0 we are able to create the sck signal
-- (sck is output of the FSM)
GEN_SCK1 : process (ck, reset)   
    begin   
        if (reset = '1') then
            count_sck1 <= (others => '0');
        elsif (ck'event and ck = '1') then
            if (en_sck1 = '1') then
                if (count_sck1 < 1948) then
                    count_sck1   <= count_sck1 + 1;
                else
                    count_sck1   <= (others => '0');
                end if;
            end if;
        end if;
    end process;

process (count_sck1)
    begin
        if (count_sck1 < 1948) then
            hit_sck1     <= '0';
        else
            hit_sck1     <= '1';
        end if;
    end process;

GEN_SCK0 : process (ck, reset)   
begin   
    if (reset = '1') then
        count_sck0 <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_sck0 = '1') then
            if (count_sck0 < 1948) then
                count_sck0   <= count_sck0 + 1;
            else
                count_sck0   <= (others => '0');
            end if;
        end if;
    end if;
end process;

process (count_sck0)
    begin
        if (count_sck0 < 1948) then
            hit_sck0     <= '0';
        else
            hit_sck0     <= '1';
        end if;
    end process;

------------------------------------------------------------------------------------
-- This process count the 16 bit to check if the whole data have been sent or not.
-- If hit_16 = 1, do the latest (timing) stuff to conclude the transmission of this data.
COUNTER_16_BIT : process (ck, reset)
    begin   
        if (reset = '1') then
            count_16    <= (others => '0');
        elsif (ck'event and ck = '1') then
            if (en_count_16 = '1') then
                if (count_16 = 15) then
                    count_16    <= (others => '0');
                else
                    count_16    <= count_16 + 1;
                end if;
            end if;
        end if;
    end process;

process (count_16)
    begin
        if (count_16 < 15) then
            hit_16     <= '0';
        else
            hit_16     <= '1';
        end if;
    end process;

------------------------------------------------------------------------------------
-- This process manages the minimum required time for negCS pulse high at the end of
-- The 16bit transmission.
-- Minimum time required is 50 ns = 2 ck cycles 
COUNTER_WAIT_CS : process (ck, reset)   
    begin
        if (reset = '1') then
            count_wait_cs <= (others => '0');
        elsif (ck'event and ck = '1') then
            if (en_count_wait_cs = '1') then
                if (count_wait_cs = 2) then      -- it is setted to 9999999999 as a trial
                    count_wait_cs <= (others => '0');
                else
                    count_wait_cs <= count_wait_cs + 1;
                end if;
            end if;
        end if;
    end process;

process (count_wait_cs)
    begin
        if (count_wait_cs < 2) then
            hit_wait_cs     <= '0';
        else
            hit_wait_cs     <= '1';
        end if;
    end process;


------------------------------------------------------------------------------------
-- "data" is received by this module and his value is charged in a local variable called
-- "reg". In one of the firsts state of the FSM, "load_data" is setted to 1. It charges
-- "data" in "reg". Then, when a complete sck period is complete, "sh_data" gets 1 as value. 
-- It's necessary the new data is loaded before the rising edge of "sck", and the shift has
-- to be done before as well
    SHIFT_REGISTER : process (ck, reset)
    begin								
        if (reset = '1') then
            reg <= (others => '0');
        elsif (ck'event and ck = '1') then		
            if (load_data = '1') then	
                reg <= unsigned (data);
            elsif (sh_data = '1') then
                reg <= reg (14 downto 0) & '0';		-- here we realize the shift operation
            end if;
        end if;
    end process;
------------------------------------------------------------------------------------
-- "s_data" is a simple wire connected to the MSB of "reg" and it has always a fixed value
    s_data <= std_logic(reg(15));

------------------------------------------------------------------------------------
FSM : process (ck, reset)
    begin
        if (reset = '1') then
            state <= IDLE;
        elsif (ck'event and ck = '1') then
            state <= state_nxt;
        end if;
    end process;

------------------------------------------------------------------------------------
-- Most of the states advance to the next by an hit_<something> signal, that comes out
-- by the counters.
FSM_inputs : process (start, hit_sck1, hit_sck0, hit_tcss, hit_16, hit_wait_cs, state)
    begin   
        case state is
            when IDLE =>
                if (start = '1') then 
                    state_nxt <= LOAD;
                else
                    state_nxt <= IDLE;
                end if;
            when LOAD => 
                state_nxt <= TCSS;
            when TCSS =>                    -- t_css is required by timing protocol
                if (hit_tcss = '1') then
                    state_nxt <= SCK1;
                else
                    state_nxt <= TCSS;
                end if;
            when SCK1 => 
                if (hit_sck1 = '1') then 
                    state_nxt <= SHIFT;
                else
                    state_nxt <= SCK1;
                end if;
            when SHIFT =>         
                state_nxt <= SCK0; 
            when SCK0 => 
                if (hit_sck0 = '1') then 
                    state_nxt <= CHECK_16;
                else
                    state_nxt <= SCK0;
                end if;   
            when CHECK_16 =>                
                if (hit_16 = '1') then      
                    state_nxt <= WAIT_CS;
                else
                    state_nxt <= SCK1;
                end if;
            when WAIT_CS => 
                if (hit_wait_cs = '1') then
                    state_nxt <= STORE;
                else
                    state_nxt <= WAIT_CS;
                end if;
            when STORE => 
                state_nxt <= LOAD;

            when others => 
                state_nxt <= IDLE;
            end case;
    end process;
            
------------------------------------------------------------------------------------
-- enables signals (en_<something>) are necessary to advance the counting of every counter
FSM_outputs : process (state)
    begin
        cs              <= '0';
        load_data       <= '0';
        sh_data         <= '0';
        sck             <= '0';
        en_sck1         <= '0';
        en_sck0         <= '0';
        en_count_16     <= '0';
        en_tcss         <= '0';
        en_count_wait_cs <= '0';
        hit_seq         <= '0';
        case state is
            when IDLE =>
                cs              <= '1'; -- as timing protocol requires
            when LOAD => 
                load_data       <= '1'; -- here we charged the new data to be sent
            when TCSS => 
                en_tcss         <= '1'; -- required by timing protocol
            when SCK1 => 
                sck             <= '1'; -- this is the signal sent to the MAX7219
                en_sck1         <= '1';
            when SHIFT =>
                sh_data         <= '1'; 
                sck             <= '1'; -- We keep sck to 1 for symmetry with the
                                        -- SCK0+CHECK16 path because there sck is 0
            when SCK0 =>                -- here sck = 0
                en_sck0         <= '1'; 
            when CHECK_16 =>            -- here sck = 0;
                en_count_16     <= '1'; 
            when WAIT_CS => 
                cs              <= '1'; -- minimum time required by timing protocol 
                                        -- to finish the 16bits transmission 
                en_count_wait_cs <= '1';
            when STORE => 
                cs               <= '1'; -- it can be removed. Unnecessary.
                hit_seq          <= '1'; -- this signal goes directly to the CONTROLLER_MAX7219
                                         -- to be counted and alert when 16bits are sent
            when others => 
                cs              <= '1';
        end case;
    end process;

end Behavioral;

