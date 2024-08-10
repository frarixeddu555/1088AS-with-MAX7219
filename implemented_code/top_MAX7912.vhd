library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_MAX7912 is 
    port (
                ck              : in std_logic;
                reset           : in std_logic;
                btn             : in std_logic;

                sck             : out std_logic;
                s_data          : out std_logic;
                cs              : out std_logic

    );

end top_MAX7912;

architecture Behavioral of top_MAX7912 is

component SPI_protocol is  
    port (
                ck          : in std_logic;
                reset       : in std_logic;
                start       : in std_logic;
                data        : in std_logic_vector (15 downto 0);

                sck              : out std_logic;
                s_data           : out std_logic;
                cs               : out std_logic;
                hit_seq          : out std_logic
    );
end component;

component CONTROLLER_MAX7219 is
    port (
                ck          : in std_logic;
                reset       : in std_logic;
                btn         : in std_logic;
                hit_seq     : in std_logic;

                data        : out std_logic_vector (15 downto 0);
                start       : out std_logic
    );
end component;

signal start        : std_logic;
signal data         : std_logic_vector (15 downto 0);
signal hit_seq      : std_logic;

begin

SPI_protocol_inst: SPI_protocol
 port map(
    ck => ck,
    reset => reset,
    start => start,
    data => data,
    sck => sck,
    s_data => s_data,
    cs => cs,
    hit_seq => hit_seq
);

CONTROLLER_MAX7219_inst: CONTROLLER_MAX7219
 port map(
    ck => ck,
    reset => reset,
    btn => btn,
    hit_seq => hit_seq,
    data => data,
    start => start
);

end Behavioral;
