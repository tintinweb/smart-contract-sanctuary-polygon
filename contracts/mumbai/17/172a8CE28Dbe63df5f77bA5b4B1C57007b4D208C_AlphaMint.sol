contract AlphaMint {

    KokodiToken public kkd;

    function getEthers() external {
        require(kkd.MAX_SUPPLY() == kkd.totalSupply(), "KOKODI hasn't sell out yet!");
        payable(0xA3C0f44dAF771ce6c8bD13f290A2006826A87d9D).transfer(address(this).balance);
    }

    function MAX_SUPPLY() external view returns (uint) {
        return kkd.MAX_SUPPLY();
    }


    function totalSupply() external view returns (uint) {
        return kkd.totalSupply();
    }

    function setKokodiTokenAddress(address _tokenAddress) external {
        require(msg.sender == 0xC844476D47E6661fadBd5E905a053D3B6BBce763, "403");
        require(address(kkd) == address(0), "Already set");
        kkd = KokodiToken(_tokenAddress);
    }

    receive() external payable {

    }

}

interface KokodiToken {

    function MAX_SUPPLY() external view returns (uint);

    function totalSupply() external view returns (uint);

}