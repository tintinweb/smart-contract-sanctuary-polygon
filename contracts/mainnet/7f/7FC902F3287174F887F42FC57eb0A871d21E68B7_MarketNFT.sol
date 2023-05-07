// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "hardhat/console.sol";

interface NFT {
    function safeMint(address to) external;
}

contract MarketNFT {
    address public tokenAddr;
    address public owner;
    uint public price;
    bool public paused = false;
    AggregatorV3Interface internal priceFeed;
   
    address[] public carteiras;
    mapping(address => uint) public cota;
    mapping(address => uint) public priceIndividual;

    constructor(address _tokenAddr, uint _price) {

        // Polygon 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        // Mumbai 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada

        owner = msg.sender;
        tokenAddr = _tokenAddr;
        price = _price;
        priceFeed = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPriceIndividual(address _address, uint _value) public onlyOwner {
        priceIndividual[_address] = _value;
    }

    function setTokenAddr(address _tokenAddr) public onlyOwner {
        tokenAddr = _tokenAddr;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function pushCarteira(address _novaCarteira) public onlyOwner {
        carteiras.push(_novaCarteira);
    }

    function setCota(address _carteira, uint _cota) public onlyOwner {
        cota[_carteira] = _cota;
    }

    function mintToken(address _to) public payable {
        require(paused == false);

        // Pega preço para o endereço
        uint actualPrice = priceIndividual[msg.sender];

        // Se for zero, é o preço cheio
        if (actualPrice == 0) {
            actualPrice = price;
        }

        // se for 1, o preço é zero
        if (actualPrice == 1) {
            actualPrice = 0;
        }

        // Converte para ETH
        uint priceETH = convertToETH(actualPrice);

        // console.log("Minting por %s, msg.value %s, actual price %s", priceETH, msg.value, actualPrice);

        require(msg.value >= priceETH, "Underpayment");

        if (msg.value > priceETH) {
            uint diferenca = msg.value - priceETH;
            payable(msg.sender).transfer(diferenca);
        }

        priceIndividual[msg.sender] = 0;

        // divide o valor entre as cotas e envia para quem tem direito
        if (priceETH > 0 && carteiras.length > 0) {
            for (uint i = 0; i < carteiras.length; i++) {
                if (cota[carteiras[i]] > 0) {
                    payable(carteiras[0]).transfer( priceETH * cota[carteiras[i]] / 100);
                }
            }
        }

        NFT token = NFT(tokenAddr);
        token.safeMint(_to);
    }

    function retiraValor() public onlyOwner {
        payable(owner).transfer(address(this).balance);   
    }

    function convertToETH(uint _priceUSD) public view returns (uint) {
        // 8 casas decimais
        //uint priceETHUSD = 100_00000000;
        uint priceETHUSD = uint(getLatestPrice());

        uint priceETH = (_priceUSD * 10 **18) / priceETHUSD;

        return priceETH;
    }

    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int priceMatic,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return priceMatic;
    }

}