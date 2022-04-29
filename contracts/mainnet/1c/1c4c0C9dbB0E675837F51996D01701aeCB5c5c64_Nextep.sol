// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";


contract Nextep is ERC721A, Ownable {
    using Strings for uint256;


    string private baseURI;

    uint256[] public wagon1IDs =[16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,128,129,130,135,136,137,138,139,143,144,145,146,147,148,149];
    uint256[] public wagon2_7IDs = [0, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85];
    uint256 public Avl_Wagon1;  
    uint256 public Avl_Wagon2;  

    uint256 public z = 0;
    uint256 public a = 0;
   
    uint256 public MAX_SUPPLY = 150;  
    uint256 public cost = 162.4 ether;
    uint256 public txnCount;
    uint256 public qualifiedTxns;
    uint256 public rewardsPool;
    uint256 public qualifiedSupply;
    uint256 public wagon1Rewards;

    bool public paused = false;


    mapping (uint256 => address) public holders;
    mapping (uint256 => uint256) public minted;

    mapping (uint256 => uint256) public mapRewards;

    constructor(string memory _initBaseURI) ERC721A("Nextep ", "NXTP") {
    
    setBaseURI(_initBaseURI);
  
    }

    function mint(uint256 quantity) public payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {

            if(supply == 150){
            revert("All tokens have been sold!");

            } else {
            require(msg.value >= (cost * quantity), "Not enough ether sent");  
            
            }
                       
            
        }

        txnCount++;
        holders[txnCount] = msg.sender; 
        minted[txnCount] = quantity; 


        _safeMint(msg.sender, quantity);

    }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    //only owner

    function wagon1_rewards(uint256 percentage) public payable onlyOwner{

        require (address(this).balance > 0, "Balance is zero");        
        mapRewards[z] =  address(this).balance * percentage / 100;

        wagon1Count();        

        for (uint256 x = 0; x < wagon1IDs.length; x++){
        if (_exists(wagon1IDs[x])){       
        (bool wagon1, ) = payable(ownerOf(wagon1IDs[x])).call{value:mapRewards[z]/Avl_Wagon1}("");
        require(wagon1);

        }
      }
      z++;

    }

    function wagon1Count() private onlyOwner {
        
        for (uint256 x = 0; x < wagon1IDs.length; x++){
            if (_exists(wagon1IDs[x])) {
              Avl_Wagon1++;
            } else {
            }
        }
    }

    
    function wagon2_rewards(uint256 percentage) public payable onlyOwner{
        require (address(this).balance > 0, "Balance is zero");

        mapRewards[a] =  address(this).balance * percentage / 100;
        wagon2Count();
        
        for (uint256 x = 0; x < wagon2_7IDs.length; x++){

        if (_exists(wagon2_7IDs[x])){       
        (bool wagon2, ) = payable(ownerOf(wagon2_7IDs[x])).call{value:mapRewards[a]/Avl_Wagon2}("");
        require(wagon2);
        }
       

      }
       a++;
    }

    function wagon2Count() private onlyOwner {
        
        for (uint256 x = 0; x < wagon2_7IDs.length; x++){
             if (_exists(wagon2_7IDs[x])){
              Avl_Wagon2++;
            } else {
            }
        }
    }



    function rewards() public payable onlyOwner{

        rewardsPool = msg.value;
        qualifiedTxns = txnCount;
        qualifiedSupply = totalSupply();

        for(uint256 x = 1 ; x <= qualifiedTxns ; x++ ){

        (bool main, ) = payable(holders[x]).call{value: rewardsPool * minted[x]/ qualifiedSupply}("");
        require(main); 
        

        }
      

    }
  
    function withdraw() public payable onlyOwner {

    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
    
    function setMintRate(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
   
}