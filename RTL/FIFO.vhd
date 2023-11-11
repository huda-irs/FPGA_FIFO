use IEEE.math_real.all;

entity fifo_single_clk is 
generic(
		G_N_SLOTS := 2;
);
port(
	clk_i			:  std_logic;
	mrst_i			:  std_logic;
	sw_rst_i		:  std_logic;
	we_i			:  std_logic;
	data_i			:  std_logic_vector(7 downto 0);
	re_i			:  std_logic;
	data_o			:  std_logic_vector(7 downto 0)
);
end entity;
architecture fifo_single_clk_arch of fifo_single_clk is 

	type storage_structure is array < natural range> of std_logic(7 downto 0);

	signal fifo_array := storage_structure(G_N_SLOTS - 1 downto 0);
	signal we_ptr	  := natural ;
	signal re_ptr	  := natural ;
	signal rdata_reg  := std_logic_vector(7 downto 0);

begin

	-- output/input data
	process(clk_i, sw_rsti, mrst_i)
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
				if(we_i = '1')
					then
					fifo_array(we_ptr) <= wdata_i;
				end if;
				if(re_i = '1')
					then
					rdata_reg <= fifo_array(re_ptr);
				end if;
			end if;
		end if;
	end process;


	-- Map reg to I/O
	data_o <= rdata_reg

end;

