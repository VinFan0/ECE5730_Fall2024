--Flag 0 - France
if (pix_count > 427) and (pix_count <= 640) then
	--BLUE = #002395
	next_next_VGA_R <= "0000";
	next_next_VGA_G <= "0010";
	next_next_VGA_B <= "1001";
elsif (pix_count > 213) and (pix_count <= 427) then
	--White = #FFFFFF
	next_next_VGA_R <= "1111";
	next_next_VGA_G <= "1111";
	next_next_VGA_B <= "1111";
elsif pix_count <= 213 then
	--RED = #ed2939
	next_next_VGA_R <= "1110";
	next_next_VGA_G <= "0010";
	next_next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;
	
--Flag 1-Italy
if (pix_count > 427) and (pix_count <= 640) then
	--GREEN = #009246
	next_next_VGA_R <= "0000";
	next_next_VGA_G <= "1001";
	next_next_VGA_B <= "0100";
elsif (pix_count > 213) and (pix_count <= 427) then
	--White = #FFFFFF
	next_next_VGA_R <= "1111";
	next_next_VGA_G <= "1111";
	next_next_VGA_B <= "1111";
elsif pix_count <= 213 then
	--RED = #ce2b37
	next_next_VGA_R <= "1100";
	next_next_VGA_G <= "0010";
	next_next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;
	
--Flag 2-Ireland
if (pix_count > 427) and (pix_count <= 640) then
	--GREEN = #169b62
	next_next_VGA_R <= "0001";
	next_next_VGA_G <= "1001";
	next_next_VGA_B <= "0110";
elsif (pix_count > 213) and (pix_count <= 427) then
	--White = #FFFFFF
	next_next_VGA_R <= "1111";
	next_next_VGA_G <= "1111";
	next_next_VGA_B <= "1111";
elsif pix_count <= 213 then
	--ORANGE = #ff883e
	next_next_VGA_R <= "1111";
	next_next_VGA_G <= "1000";
	next_next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;	
	
--Flag 3-Belgium
if (pix_count > 427) and (pix_count <= 640) then
	--BLACK = #000000
	next_next_VGA_R <= "0000";
	next_next_VGA_G <= "0000";
	next_next_VGA_B <= "0000";
elsif (pix_count > 213) and (pix_count <= 427) then
	--Yellow = #fae042
	next_next_VGA_R <= "1111";
	next_next_VGA_G <= "1110";
	next_next_VGA_B <= "0100";
elsif pix_count <= 213 then
	--RED = #ed2939
	next_next_VGA_R <= "1110";
	next_next_VGA_G <= "0010";
	next_next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 4-Mali	
if (pix_count > 427) and (pix_count <= 640) then
	--GREEN = #14b53a
	next_next_VGA_R <= "0001";
	next_next_VGA_G <= "1011";
	next_next_VGA_B <= "0011";
elsif (pix_count > 213) and (pix_count <= 427) then
	--Yellow = #fcd116
	next_next_VGA_R <= "1111";
	next_next_VGA_G <= "1101";
	next_next_VGA_B <= "0001";
elsif pix_count <= 213 then
	--RED = #ce1126
	next_next_VGA_R <= "1100";
	next_next_VGA_G <= "0001";
	next_next_VGA_B <= "0010";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 5-Chad	
if (pix_count > 427) and (pix_count <= 640) then
	--BLUE = #002664
	next_VGA_R <= "0000";
	next_VGA_G <= "0010";
	next_VGA_B <= "0110";
elsif (pix_count > 213) and (pix_count <= 427) then
	--Yellow = #fecb00
	next_VGA_R <= "1111";
	next_VGA_G <= "1100";
	next_VGA_B <= "0000";
elsif pix_count <= 213 then
	--RED = #c60c30
	next_VGA_R <= "1100";
	next_VGA_G <= "0000";
	next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 6-Nigeria
if (pix_count > 427) and (pix_count <= 640) then
	--GREEN = #008751
	next_VGA_R <= "0000";
	next_VGA_G <= "1000";
	next_VGA_B <= "0101";
elsif (pix_count > 213) and (pix_count <= 427) then
	--WHITE = #FFFFFF
	next_VGA_R <= "1111";
	next_VGA_G <= "1111";
	next_VGA_B <= "1111";
elsif pix_count <= 213 then
	--GREEN = #008751
	next_VGA_R <= "0000";
	next_VGA_G <= "1000";
	next_VGA_B <= "0101";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 7-Ivory Coast
if (pix_count > 427) and (pix_count <= 640) then
	--Orange = #f77f00
	next_VGA_R <= "1111";
	next_VGA_G <= "1001";
	next_VGA_B <= "0000";
elsif (pix_count > 213) and (pix_count <= 427) then
	--WHITE = #FFFFFF
	next_VGA_R <= "1111";
	next_VGA_G <= "1111";
	next_VGA_B <= "1111";
elsif pix_count <= 213 then
	--GREEN = #009e60
	next_VGA_R <= "0000";
	next_VGA_G <= "1001";
	next_VGA_B <= "0110";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 8-Poland
if (lin_count > 45) and (lin_count <= 285) then
	--WHITE = #FFFFFF
	next_VGA_R <= "1111";
	next_VGA_G <= "1111";
	next_VGA_B <= "1111";
elsif (lin_count > 285) and (lin_count <= 525) then
	--RED = #dc143c
	next_VGA_R <= "1101";
	next_VGA_G <= "0001";
	next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 9-Germany
if (lin_count > 45) and (lin_count <= 205) then
	--BLACK = #000000
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
elsif (lin_count > 205) and (lin_count <= 365) then
	--RED = #dd0000
	next_VGA_R <= "1101";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
elsif (lin_count > 365) and (lin_count <= 525) then
	--YELLOW = #ffce00
	next_VGA_R <= "1111";
	next_VGA_G <= "1100";
	next_VGA_B <= "0000";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;

--Flag 10-Austria
if (lin_count > 45) and (lin_count <= 205) then
	--RED = #ed2939
	next_VGA_R <= "1110";
	next_VGA_G <= "0010";
	next_VGA_B <= "0011";
elsif (lin_count > 205) and (lin_count <= 365) then
	--WHITE = #FFFFFF
	next_VGA_R <= "1111";
	next_VGA_G <= "1111";
	next_VGA_B <= "1111";
elsif (lin_count > 365) and (lin_count <= 525) then
	--RED = #ed2939
	next_VGA_R <= "1110";
	next_VGA_G <= "0010";
	next_VGA_B <= "0011";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;
	
--Flag 11-Republic of Congo
i = 160
j = 0
if (pix_count > i) and (pix_count <= 640) then
	--GREEN = #009543
	next_VGA_R <= "0000";
	next_VGA_G <= "1001";
	next_VGA_B <= "0100";
elsif(pix_count <= i) and (pix_count > j) then
	--YELLOW = #fbde4a
	next_VGA_R <= "1111";
	next_VGA_G <= "1101";
	next_VGA_B <= "0100";
elsif(pix_count <= j) and (pix_count > 0) then
	--RED = #dc241f
	next_VGA_R <= "1101";
	next_VGA_G <= "0010";
	next_VGA_B <= "0001";
else
	next_VGA_R <= "0000";
	next_VGA_G <= "0000";
	next_VGA_B <= "0000";
end if;
i++
j++