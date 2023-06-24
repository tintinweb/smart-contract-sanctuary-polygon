/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * Maintains a list of interested wallets for the
 * magikdrops project based on NFTs. This records
 * will become part of the project's whitelists programs.
 *
 * @title MagikdropsWhitelist
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract MagikdropsWhitelist {

    mapping(address => bool) private list;
    mapping(address => address) private nft;
    mapping(address => uint ) private nft_id;
    mapping(address => uint) private honors;

     uint private _count = 0;
     bool private active = true;
    
    address owner; 

    constructor() {
        owner = msg.sender; 
    }


/**
* Please check if list is accepting submits
*/
    function isActive() public view returns ( bool ractive ){
        ractive = active;
    }
    
/**
* Register your interest here !
*/
    function addMe() public {
        add();
        delete nft[ msg.sender ];
        delete nft_id[ msg.sender ];
    }

/**
* Register your interest and suggest one of your NFTs already
*/
    function addMeWithNFT( address contract_addr, uint tokenId) public {
        //May require validation later
        add();
        nft[ msg.sender ] = contract_addr;
        nft_id[ msg.sender ] = tokenId;
    }

/**
* Register your interest and donate
*/
    function addMeWithHonors() external payable  {
        add();
        honors[ msg.sender ] += msg.value;
    }

/**
* List Management
*/
    function setClosed() public onlyOwner {
        active = false;
    }
    function setOpen() public onlyOwner {
        active = true;
    }
    function transfer( address payable to, uint256 amount) public onlyOwner   {
        require(msg.sender==owner);
        to.transfer(amount);
    }
    function transferOwner(address to) public onlyOwner{
        owner = to;
    }

    
/**
* You can check already submitted items
*/
    function isIn( address query ) public view returns ( bool added, address contract_addr, uint tokenId ) {
        added = list[ query ];
        contract_addr = nft[ query];
        tokenId = nft_id[ query ];
    }

    function hasHonors( address query ) public view returns ( bool added, uint amount ) {
        added = list[ query ];
        if(honors[query]>0){
            amount = honors[query];
        }else{
            amount = 0;
        }
    }
    function count() public view returns (uint total ) {
        return _count;
    }

/**
*   Util
*/
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function add() private{
        require( active == true );
        if(!list[ msg.sender ]) _count++;
        list[ msg.sender ] = true;
    }
}