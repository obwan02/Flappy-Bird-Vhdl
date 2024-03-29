library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.types.all;
use work.constants;

entity pipes is
    port(
        PipeClk, Enable, Reset: in std_logic;
        PipeWidth: out signed(10 downto 0);
        Rand: in std_logic_vector(7 downto 0);
        PipesXValues: out PipesArray;
        TopPipeHeights: out PipesArray;
        BottomPipeHeights: out PipesArray;

        Speed: out signed(9 downto 0);

        IsTraining: in std_logic;
        ScoreTens: in std_logic_vector(3 downto 0);
        Trigger: in std_logic;
        Done: out std_logic := '0'
    );
end entity pipes;
 

architecture construction of pipes is
    signal s_Done: std_logic := '0';
begin

    Done <= s_Done;
    PipeWidth <= to_signed(constants.PIPE_WIDTH, 11);

    UPDATE: process(PipeClk)
        constant RightMostPixel: signed(10 downto 0) := to_signed(640, 11);
        constant TrainingSpeed: signed(9 downto 0) := to_signed(2, 10);
        constant TempHeight: signed(10 downto 0) := to_signed(100, 11);

        variable v_NormalSpeed: signed(9 downto 0) := to_signed(1, 10);
        variable v_prevTensScore: std_logic_vector(3 downto 0) := (others => '0');

        variable v_Index: unsigned(3 downto 0);
        variable v_PipesXValues: PipesArray := (to_signed(100, 11), 
                                                to_signed(200 + 80, 11), 
                                                to_signed(300 + 160, 11),  
                                                to_signed(400 + 240, 11));
    begin
        if rising_edge(PipeClk) then

            if Reset = '1' then 
                for i in 0 to constants.PIPE_MAX_INDEX loop 
                    v_PipesXValues(i) := to_signed(100*(i+1)+ i*constants.PIPE_WIDTH, 11);
                    BottomPipeHeights(i) <= (others => '0');
                    TopPipeHeights(i) <= (others => '0');
                end loop;
            end if;

            if Trigger = '0' then
               v_Index := (others => '0');
               s_Done <= '0';
            end if;

            if (Trigger = '1' and s_Done = '0') and Enable = '1' then 
                if (v_PipesXValues(to_integer(v_Index)) + constants.PIPE_WIDTH <= 0) then

                    v_PipesXValues(to_integer(v_Index)) := RightMostPixel - (v_PipesXValues(to_integer(v_Index)) + constants.PIPE_WIDTH);

                    --asign the randomly generated heigt to the top pipes
                    TopPipeHeights(to_integer(v_Index)) <= signed("000" & Rand);

                    -- find the bottom piprd height
                    BottomPipeHeights(to_integer(v_Index)) <= constants.SCREEN_HEIGHT - (signed("000" & Rand) + 200);
                    
                else
                    if IsTraining = '1' then
                        v_PipesXValues(to_integer(v_Index)) := v_PipesXValues(to_integer(v_Index)) - TrainingSpeed;
                    else
                        v_NormalSpeed(4 downto 0) := signed("0" & ScoreTens) + 1;    
                        if v_NormalSpeed >= constants.MAX_SPEED then 
                            v_NormalSpeed := to_signed(constants.MAX_SPEED, 10);
                        end if;
                        v_PipesXValues(to_integer(v_Index)) := v_PipesXValues(to_integer(v_Index)) - v_NormalSpeed;
                    end if;
                end if;

                if v_Index = to_unsigned(3, 3) then 
                    s_Done <= '1';
                    v_Index := (others => '0');
                else
                    v_Index := v_Index + 1;
                end if;

            end if;
        end if;

        if IsTraining = '1' then 
            Speed <= TrainingSpeed;
        else
            Speed <= v_NormalSpeed;
        end if;

        PipesXValues <= v_PipesXValues;
    end process;

end architecture;
