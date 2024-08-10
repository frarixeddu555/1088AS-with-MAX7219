-----------------------------------------------------------------------------------------
-- From this module we control what we want to send to the MAX7219 device (passing before
-- by the SPI_protocol module).
-- There are some constant declarations that can be used for initialize "data", signal sent
-- to SPI_protocol that transform it from a 16bits signal in a serial data.
-- d0,d1,. . .,d7 variable represent the matrix LED rows, c0,c1, . . ., c7 the columns.
-- Signal declarations named "Register Address Map" must be the 8 left-most bits of data.
-- The 8 righ-most bits of "data" might get the rest of the constant declarations (each
-- declaration title report the right Address Register to be matched with).   
-- We thought on this constant declarations to make more easy to read and implement
-- the functionality desired for the matrix LED.

--          8x8 MATRIX
--   +--+--+--+--+--+--+--+--+
-- d7|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d6|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d5|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d4|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d3|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d2|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d1|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
-- d0|  |  |  |  |  |  |  |  |
--   +--+--+--+--+--+--+--+--+
--    c0 c1 c2 c3 c4 c5 c6 c7

-----------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CONTROLLER_MAX7219 is
    port (
        ck          : in std_logic; -- 50 MHz
        reset       : in std_logic;
		btn         : in std_logic; -- received by an extern FPGA button
        hit_seq     : in std_logic; -- received by SPI_protocol module to notify
                                    -- the end of a 16bits sequence

        data        : out std_logic_vector (15 downto 0); -- sent to CONTROLLER_MAX7219 module
        start       : out std_logic                       -- sent to CONTROLLER_MAX7219 module
    );

end CONTROLLER_MAX7219;

architecture Behavioral of CONTROLLER_MAX7219 is

-- Register Address Map -- to set a certain value in a certain register
constant no_op       : std_logic_vector (7 downto 0) := x"00";
constant d0          : std_logic_vector (7 downto 0) := x"01"; -- row 0
constant d1          : std_logic_vector (7 downto 0) := x"02"; -- row 1
constant d2          : std_logic_vector (7 downto 0) := x"03"; -- row 2
constant d3          : std_logic_vector (7 downto 0) := x"04"; -- row 3
constant d4          : std_logic_vector (7 downto 0) := x"05"; -- row 4
constant d5          : std_logic_vector (7 downto 0) := x"06"; -- row 5
constant d6          : std_logic_vector (7 downto 0) := x"07"; -- row 6
constant d7          : std_logic_vector (7 downto 0) := x"08"; -- row 7
constant decode_mode : std_logic_vector (7 downto 0) := x"09"; -- 7-seg decode 
constant intensity   : std_logic_vector (7 downto 0) := x"0A"; -- to adjust brightness
constant scan_limit  : std_logic_vector (7 downto 0) := x"0B"; -- to adjust the number of the working leds
constant shutdown    : std_logic_vector (7 downto 0) := x"0C"; -- battery-saver mode
constant display_test: std_logic_vector (7 downto 0) := x"0F"; -- default display test

-- Columns Map. These must be matched with a d0,d1, . . ., d7 signal
constant c0 : std_logic_vector(7 downto 0) := "00000001"; 
constant c1 : std_logic_vector(7 downto 0) := "00000010";
constant c2 : std_logic_vector(7 downto 0) := "00000100";
constant c3 : std_logic_vector(7 downto 0) := "00001000";
constant c4 : std_logic_vector(7 downto 0) := "00010000";
constant c5 : std_logic_vector(7 downto 0) := "00100000";
constant c6 : std_logic_vector(7 downto 0) := "01000000";
constant c7 : std_logic_vector(7 downto 0) := "10000000";
constant c_null : std_logic_vector(7 downto 0) := "00000000";

-- Decode-Mode Register 0x"X9--"
constant no_decode    : std_logic_vector (7 downto 0) := x"00"; --put off the 7-seg decode

--Shutdown Register 0x"XC--"
constant normal_operation_shutdown : std_logic_vector (7 downto 0) := x"01";

-- Intensity Register 0x"XA--"
constant intensity_1_32  : std_logic_vector (7 downto 0) := x"00";
constant intensity_3_32  : std_logic_vector (7 downto 0) := x"01";
constant intensity_5_32  : std_logic_vector (7 downto 0) := x"02";
constant intensity_7_32  : std_logic_vector (7 downto 0) := x"03";
constant intensity_9_32  : std_logic_vector (7 downto 0) := x"04";
constant intensity_11_32 : std_logic_vector (7 downto 0) := x"05";
constant intensity_13_32 : std_logic_vector (7 downto 0) := x"06";
constant intensity_15_32 : std_logic_vector (7 downto 0) := x"07";
constant intensity_17_32 : std_logic_vector (7 downto 0) := x"08";
constant intensity_19_32 : std_logic_vector (7 downto 0) := x"09";
constant intensity_21_32 : std_logic_vector (7 downto 0) := x"0A";
constant intensity_23_32 : std_logic_vector (7 downto 0) := x"0B";
constant intensity_25_32 : std_logic_vector (7 downto 0) := x"0C";
constant intensity_27_32 : std_logic_vector (7 downto 0) := x"0D";
constant intensity_29_32 : std_logic_vector (7 downto 0) := x"0E";
constant intensity_31_32 : std_logic_vector (7 downto 0) := x"0F";

-- Scan-Limit Register 0x"XB--"
constant display_digits_01234567 : std_logic_vector (7 downto 0) := x"07"; -- this value makes working
                                                                           -- the whole led of a row

-- Display-Test 0x"XF--"
constant normal_operation_display : std_logic_vector (7 downto 0) := x"00"; 

signal init_seq                     : unsigned (3 downto 0);
signal en_init_frame                : std_logic;
signal hit_init_frame               : std_logic;
signal seq                      : unsigned (3 downto 0);
signal en_seq                   : std_logic;

signal frame                    : unsigned (3 downto 0);
signal en_frame                 : std_logic;
signal hit_frame                : std_logic;

signal count_delay_eye        : unsigned (23 downto 0);
signal hit_delay_eye          : std_logic;
signal en_delay_eye           : std_logic;

signal en_nxt_data            : std_logic;

signal hit_7seq               : std_logic;
signal hit_7frame             : std_logic;

signal hit_pattern       : std_logic;

type state_t is (IDLE, INIT, SEND_DATA, WAIT_SEQ, ATT_SEQ, ATT_FRAME, WAIT_ATT_FRAME, DELAY_EYE, FINISH);
    signal state, state_nxt : state_t;

begin

-----------------------------------------------------------------------------------------
-- We define "sequence" a single 16bit data sent. This process output an hit when
-- 7 data are sent, in normal operation, 7 rows, each one with its certain column pattern
-- values initialized.
SEL_SEQ : process (ck, reset)
    begin
        if (reset = '1') then
            seq <= (others => '0');
        elsif (ck'event and ck = '1') then
            if (en_seq = '1') then   
                if (seq < 7) then
                    seq <= seq + 1;
                else
                    seq <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    process (seq)
    begin
        if (seq < 7) then
            hit_7seq     <= '0';
        else
            hit_7seq     <= '1';
        end if;
    end process;

-----------------------------------------------------------------------------------------
-- We define "frame" the collection of 7 sequences that allow us to see a stable image
-- for a certain, predetermined, period time.
SEL_FRAME : process (ck, reset)
begin
    if (reset = '1') then
        frame <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_frame = '1') then 
            if (frame < 15) then 
                frame <= frame + 1;
            else
                frame <= x"1";   -- so we won't execute the register initialization cycle
            end if;              -- during the frame loops.
        end if;
    end if;
end process;

process (frame)
    begin
        if (frame < 15) then
            hit_7frame     <= '0';
        else
            hit_7frame     <= '1';
        end if;
    end process;

-----------------------------------------------------------------------------------------
-- This process manages how much time the frame (single image represented on the matrix)
-- must be displayed. Naturally, we must set a minimum amount of time for our to perceive
-- the correct flow of the succession of images. 
COUNT_DELAY_EYE_proc : process (ck, reset)   -- it generates 60ns sck UP and 60ns sck DOWN 
    begin   
        if (reset = '1') then
            count_delay_eye <= (others => '0');
        elsif (ck'event and ck = '1') then
            if (en_delay_eye = '1') then
                if (count_delay_eye < 2499999) then
                    count_delay_eye   <= count_delay_eye + 1;
                else
                    count_delay_eye   <= (others => '0');
                end if;
            end if;
        end if;
    end process;

process (count_delay_eye)
    begin
        if (count_delay_eye < 2499999) then
            hit_delay_eye     <= '0';
        else
            hit_delay_eye     <= '1';
        end if;
    end process;

-----------------------------------------------------------------------------------------
-- this process is provvisory in the intent to allow the stream of one sole image throughout a 
-- series of LED matrix modules instead of the repetition of the same stream sequences in each 
-- LED matrix at the same time

-- process (ck, reset)
--     begin
--         if (reset = '1') then
--             count_delay_matrix <= (others => '0');
--         elsif (ck'event and ck = '1') then
--             if (en_delay_matrix = '1') then   
--                 if (count_delay_matrix < 99999999) then
--                     count_delay_matrix <= count_delay_matrix + 1;
--                 else
--                     count_delay_matrix <= (others => '0');
--                 end if;
--             end if;
--         end if;
--     end process;

--     process (count_delay_matrix)
--     begin
--         if (count_delay_matrix < 99999999) then
--             hit_delay_matrix     <= '0';
--         else
--             hit_delay_matrix     <= '1';
--         end if;
--     end process;

-----------------------------------------------------------------------------------------
-- This process is managed by selectors (seq and frame), that choose a specific sequence 
-- of a specific frame according to what we want to represent in the LED matrix. 
-- The case "frame=0" correspond to the initializazion of the MAX7219 registers to allow
-- the correct use of the decoder to drive matrices rather than 7-seg displays.
-- Once frame=0 is esecuted, it is no longer because it is not included in the loop logic
-- (look at SEL_FRAME process).
-- Every other frame loop will start from frame=1.
-- Excluding the first frame, there are 15 frames that realize the visualization of an 
-- "arrow" moving from left to the right.
MEMORY_proc : process(ck, reset)
    begin
        if (reset = '1') then
            data <= no_op & c_null;
        elsif (ck'event and ck = '1') then
                case frame is 
                    when x"0" => 
                        case seq is
                            when x"0" => 
                                data <= no_op & c_null; 
                            when x"1" => 
                                data <= shutdown & normal_operation_shutdown;
                            when x"2" =>
                                data <= decode_mode & no_decode;
                            when x"3" =>
                                data <= intensity & intensity_23_32;
                            when x"4" =>
                                data <= scan_limit & display_digits_01234567;
                            when x"5" =>
                                data <= display_test & normal_operation_display; 
                            when x"6" =>
                                data <= no_op & c_null;
                            when x"7" =>
                                data <= no_op & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;
                    when x"1" => 
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null; -- no led of the first row is on.
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & c_null;
                            when x"3" =>
                                data <= d3 & c0;
                            when x"4" =>
                                data <= d4 & c0;
                            when x"5" =>
                                data <= d5 & c_null;
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"2" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & c0;        -- the left-most led of 3rd row is on
                            when x"3" =>
                                data <= d3 & (c0 or c1);    -- the first and second led of the 4th row are on
                            when x"4" =>
                                data <= d4 & (c0 or c1);
                            when x"5" =>
                                data <= d5 & c0;
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"3" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c0;
                            when x"2" =>
                                data <= d2 & (c0 or c1);
                                when x"3" =>
                                data <= d3 & (c0 or c1 or c2);
                            when x"4" =>
                                data <= d4 & (c0 or c1 or c2);
                            when x"5" =>
                                data <= d5 & (c0 or c1);
                            when x"6" =>
                                data <= d6 & c0;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"4" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c0;
                            when x"1" =>
                                data <= d1 & (c0 or c1);
                            when x"2" =>
                                data <= d2 & (c0 or c1 or c2);
                            when x"3" =>
                                data <= d3 & (c0 or c1 or c2 or c3);
                            when x"4" =>
                                data <= d4 & (c0 or c1 or c2 or c3);
                            when x"5" =>
                                data <= d5 & (c0 or c1 or c2);
                            when x"6" =>
                                data <= d6 & (c0 or c1);
                            when x"7" =>
                                data <= d7 & c0;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"5" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c1;
                            when x"1" =>
                                data <= d1 & (c1 or c2);
                            when x"2" =>
                                data <= d2 & (c0 or c1 or c2 or c3);
                            when x"3" =>
                                data <= d3 & (c0 or c1 or c2 or c3 or c4);
                            when x"4" =>
                                data <= d4 & (c0 or c1 or c2 or c3 or c4);
                            when x"5" =>
                                data <= d5 & (c0 or c1 or c2 or c3);
                            when x"6" =>
                                data <= d6 & (c1 or c2);
                            when x"7" =>
                                data <= d7 & c1;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"6" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c2;
                            when x"1" =>
                                data <= d1 & (c2 or c3);
                            when x"2" =>
                                data <= d2 & (c0 or c1 or c2 or c3 or c4);
                            when x"3" =>
                                data <= d3 & (c0 or c1 or c2 or c3 or c4 or c5);
                            when x"4" =>
                                data <= d4 & (c0 or c1 or c2 or c3 or c4 or c5);
                            when x"5" =>
                                data <= d5 & (c0 or c1 or c2 or c3 or c4);
                            when x"6" =>
                                data <= d6 & (c2 or c3);
                            when x"7" =>
                                data <= d7 & c2;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"7" =>
                        case seq is
                            when x"0" =>
                            data <= d0 & c3;
                        when x"1" =>
                            data <= d1 & (c3 or c4);
                        when x"2" =>
                            data <= d2 & (c0 or c1 or c2 or c3 or c4 or c5);
                        when x"3" =>
                            data <= d3 & (c0 or c1 or c2 or c3 or c4 or c5 or c6);
                        when x"4" =>
                            data <= d4 & (c0 or c1 or c2 or c3 or c4 or c5 or c6);
                        when x"5" =>
                            data <= d5 & (c0 or c1 or c2 or c3 or c4 or c5);
                        when x"6" =>
                            data <= d6 & (c3 or c4);
                        when x"7" =>
                            data <= d7 & c3;

                        when others =>
                            data <= no_op & c_null;
                    end case;

                    when x"8" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c4;
                            when x"1" =>
                                data <= d1 & (c4 or c5);
                            when x"2" =>
                                data <= d2 & (c0 or c1 or c2 or c3 or c4 or c5 or c6);
                            when x"3" =>
                                data <= d3 & (c0 or c1 or c2 or c3 or c4 or c5 or c6 or c7);
                            when x"4" =>
                                data <= d4 & (c0 or c1 or c2 or c3 or c4 or c5 or c6 or c7);
                            when x"5" =>
                                data <= d5 & (c0 or c1 or c2 or c3 or c4 or c5 or c6);
                            when x"6" =>
                                data <= d6 & (c4 or c5);
                            when x"7" =>
                                data <= d7 & c4;

                            when others =>
                                data <= no_op & c_null;
                        end case;
                    when x"9" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c5;
                            when x"1" =>
                                data <= d1 & (c5 or c6);
                            when x"2" =>
                                data <= d2 & (c1 or c2 or c3 or c4 or c5 or c6 or c7);
                            when x"3" =>
                                data <= d3 & (c1 or c2 or c3 or c4 or c5 or c6 or c7);
                            when x"4" =>
                                data <= d4 & (c1 or c2 or c3 or c4 or c5 or c6 or c7);
                            when x"5" =>
                                data <= d5 & (c1 or c2 or c3 or c4 or c5 or c6 or c7);
                            when x"6" =>
                                data <= d6 & (c5 or c6);
                            when x"7" =>
                                data <= d7 & c5;
                    
                            when others =>
                                data <= no_op & c_null;
                        end case;
                    
                    when x"A" =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c6;
                            when x"1" =>
                                data <= d1 & (c6 or c7);
                            when x"2" =>
                                data <= d2 & (c2 or c3 or c4 or c5 or c6 or c7);
                            when x"3" =>
                                data <= d3 & (c2 or c3 or c4 or c5 or c6 or c7);
                            when x"4" =>
                                data <= d4 & (c2 or c3 or c4 or c5 or c6 or c7);
                            when x"5" =>
                                data <= d5 & (c2 or c3 or c4 or c5 or c6 or c7);
                            when x"6" =>
                                data <= d6 & (c6 or c7);
                            when x"7" =>
                                data <= d7 & c6;

                            when others =>
                                data <= no_op & c_null;
                        end case;
                    
                    when x"B" => 
                        case seq is
                            when x"0" =>
                                data <= d0 & c7;
                            when x"1" =>
                                data <= d1 & c7;
                            when x"2" =>
                                data <= d2 & (c3 or c4 or c5 or c6 or c7);
                            when x"3" =>
                                data <= d3 & (c3 or c4 or c5 or c6 or c7);
                            when x"4" =>
                                data <= d4 & (c3 or c4 or c5 or c6 or c7);
                            when x"5" =>
                                data <= d5 & (c3 or c4 or c5 or c6 or c7);
                            when x"6" =>
                                data <= d6 & c7;
                            when x"7" =>
                                data <= d7 & c7;

                            when others =>
                                data <= no_op & c_null;
                        end case;
                    
                    when x"C" => 
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & (c4 or c5 or c6 or c7);
                            when x"3" =>
                                data <= d3 & (c4 or c5 or c6 or c7);
                            when x"4" =>
                                data <= d4 & (c4 or c5 or c6 or c7);
                            when x"5" =>
                                data <= d5 & (c4 or c5 or c6 or c7);
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"D" => 
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & (c5 or c6 or c7);
                            when x"3" =>
                                data <= d3 & (c5 or c6 or c7);
                            when x"4" =>
                                data <= d4 & (c5 or c6 or c7);
                            when x"5" =>
                                data <= d5 & (c5 or c6 or c7);
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when x"E" => 
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & (c6 or c7);
                            when x"3" =>
                                data <= d3 & (c6 or c7);
                            when x"4" =>
                                data <= d4 & (c6 or c7);
                            when x"5" =>
                                data <= d5 & (c6 or c7);
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;
                    
                        when x"F" => 
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & (c7);
                            when x"3" =>
                                data <= d3 & (c7);
                            when x"4" =>
                                data <= d4 & (c7);
                            when x"5" =>
                                data <= d5 & (c7);
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;

                    when others =>
                        case seq is
                            when x"0" =>
                                data <= d0 & c_null;
                            when x"1" =>
                                data <= d1 & c_null;
                            when x"2" =>
                                data <= d2 & c_null;
                            when x"3" =>
                                data <= d3 & c_null;
                            when x"4" =>
                                data <= d4 & c_null;
                            when x"5" =>
                                data <= d5 & c_null;
                            when x"6" =>
                                data <= d6 & c_null;
                            when x"7" =>
                                data <= d7 & c_null;

                            when others =>
                                data <= no_op & c_null;
                        end case;
                    end case;
            end if;
        -- end if;
        end process;

                
FSM_CONTROLLER : process (ck, reset)
    begin
        if (reset = '1') then
            state <= IDLE;
        elsif (ck'event and ck = '1') then
            state <= state_nxt;
        end if;
    end process;

process (state, btn, hit_seq, hit_7seq, hit_7frame, hit_delay_eye)
    begin
        case state is
            when IDLE => 
                if (btn = '1') then 
                    state_nxt <= INIT;
                else
                    state_nxt <= IDLE;
                end if;
            when INIT => 
                state_nxt <= SEND_DATA;
            when SEND_DATA =>
                state_nxt <= WAIT_SEQ;
            when WAIT_SEQ => 
                if (hit_seq = '1') then
                    state_nxt <= ATT_SEQ;
                elsif (hit_7seq = '1') then 
                    state_nxt <= WAIT_ATT_FRAME;
                elsif (hit_7frame = '1') then 
                    state_nxt <= FINISH;
                else
                    state_nxt <= WAIT_SEQ;
                end if;
            when ATT_SEQ => 
                state_nxt <= WAIT_SEQ;
            when ATT_FRAME => 
                state_nxt <= WAIT_SEQ;
            when WAIT_ATT_FRAME => 
                if (hit_seq = '1') then
                    state_nxt <= DELAY_EYE;
                else
                    state_nxt <= WAIT_ATT_FRAME;
                end if;
            when DELAY_EYE => 
                if (hit_delay_eye = '1') then 
                    state_nxt <= ATT_FRAME;
                else
                    state_nxt <= DELAY_EYE;
                end if;
            when FINISH => 
                state_nxt <= WAIT_SEQ;

            when others => 
                state_nxt <= IDLE;
            end case;
        end process;

process (state)
    begin
        start           <= '0';
        en_seq          <= '0';
        en_frame        <= '0';
        en_delay_eye    <= '0';

        case state is
            when IDLE => 
            when INIT => 
            when SEND_DATA => 
                start        <= '1';
            when WAIT_SEQ => 
            when ATT_SEQ => 
                en_seq  <= '1';
            when ATT_FRAME => 
                en_frame    <= '1';
                en_seq      <= '1';
            when WAIT_ATT_FRAME => 
            when DELAY_EYE => 
                en_delay_eye    <= '1';
            when FINISH => 
               
            when others => 

            end case;
        end process;


            





end Behavioral;
