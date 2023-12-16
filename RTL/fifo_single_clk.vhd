library ieee;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use IEEE.math_real.all;

entity fifo_single_clk is 
generic(
		G_DEPTH : natural:= 2
);
port(
	clk_i			:  in  std_logic;
	mrst_i			:  in  std_logic;
	sw_rst_i		:  in  std_logic;
	we_i			:  in  std_logic;
	data_i			:  in  std_logic_vector(7 downto 0);
	re_i			:  in  std_logic;
	data_o			:  out std_logic_vector(7 downto 0)
);
end entity;
architecture fifo_single_clk_arch of fifo_single_clk is 

	type storage_structure is array (natural range<>) of std_logic_vector(7 downto 0);

	signal fifo_array 	: storage_structure(G_DEPTH - 1 downto 0);
	signal we_ptr	  	: natural ;
	signal re_ptr	  	: natural ;
	signal rdata_reg  	: std_logic_vector(7 downto 0);
	signal FIFO_COUNT 	: natural range 0 to G_DEPTH - 1;
	signal full_fifo	: std_logic;
	signal empty_fifo	: std_logic;

begin

	-- output/input data
	process(clk_i, sw_rst_i, mrst_i)
	begin
		if(mrst_i = '0')
			then
			rdata_reg <= (others => '0');
		elsif(rising_edge(clk_i))
			then
			if(sw_rst_i = '1')
				then
				rdata_reg <= (others => '0');
			else
				if(we_i = '1' and full_fifo = '0')
					then
					fifo_array(we_ptr) <= data_i;
				end if;
				if(re_i = '1' and empty_fifo = '0')
					then
					rdata_reg <= fifo_array(re_ptr);
				end if;
			end if;
		end if;
	end process;

	-- process to count how much space is remaining in the FIFO
	process(clk_i, sw_rst_i, mrst_i)
	begin
		if(mrst_i = '0')
			then
			FIFO_COUNT <= G_DEPTH;
		elsif(rising_edge(clk_i))
			then
			if(sw_rst_i = '1')
				then 
				FIFO_COUNT <= G_DEPTH;
			elsif(we_i = '1' and re_i = '0')
				then
				FIFO_COUNT <= FIFO_COUNT - 1;
			elsif(we_i = '0' and re_i = '1')
				then
				FIFO_COUNT <= FIFO_COUNT + 1;
			end if;
		end if;
	end process;

	-- read and write pointer
	process(clk_i, sw_rst_i, mrst_i)
	begin
		if(mrst_i = '0')
			then
			we_ptr <= 0;
			re_ptr <= 0;
		elsif(rising_edge(clk_i))
			then
			if(sw_rst_i = '1')
				then
				we_ptr <= 0;
				re_ptr <= 0;
			else
				if(we_i = '1' and full_fifo = '0')
					then
					if(we_ptr = G_DEPTH-1)
						then
							we_ptr <= 0;
					else
						we_ptr <= we_ptr + 1;
					end if;
				end if;

				if(re_i = '1' and empty_fifo = '0')
					then
					if(re_ptr = G_DEPTH-1)
						then
							re_ptr <= 0;
					else
						re_ptr <= we_ptr + 1;
					end if;
				end if;

			end if;
		end if;
	end process;

	-- Combinational logic
	full_fifo 	<= 	'1' when FIFO_COUNT = 0
						else '0';

	empty_fifo <= 	'1' when FIFO_COUNT = G_DEPTH
						else '0';

	-- Map reg to I/O
	data_o <= rdata_reg;

end;

