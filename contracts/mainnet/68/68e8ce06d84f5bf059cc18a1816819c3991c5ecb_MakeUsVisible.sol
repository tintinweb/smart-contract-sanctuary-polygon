// SPDX-License-Identifier: MIT
/* 
  /\  /\/ __\ /___\/   \/__\
 / /_/ / /   //  // /\ /_\  
/ __  / /___/ \_// /_///__  
\/ /_/\____/\___/___,'\__/ 

Visit https://events.pollinate.co/#/make-us-visible for project details.
Contract Developed by https://hcode.tech/

*/

pragma solidity ^0.8.2;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract MakeUsVisible is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    // opensea required name and symbol to be string

    string public name;
    string public symbol;
    string public constant _tokenUri = 
    "https://gateway.pinata.cloud/ipfs/QmXPjHhg54iEq6BXq5WZ413FXtGdYbN4e6sG8ZB5PtaRca";
    
    // using maxSupply also as TOKEN_ID 
    uint256 private constant maxSupply = 2022;
    uint256 public mintedCount;
    uint256 public salePrice = 175 ether;
    bool public sale = false;
    mapping (address => uint256) perWalletMintRecord;
    uint256 perWalletMintLimit = 10; // if this will not change, it's better to not declare .
    address private muv721Address;

    
    constructor() ERC1155(_tokenUri) {
        name = "MakeUsVisible";
        symbol = "MUV";
    }


    
    // toggle functions to change bool varibales
    function toggleSale() public onlyOwner {
        sale = !sale;
    }

    // setters for different limits

    function setSalePrice(uint256 price) public onlyOwner {
        require(price > 0, "price must be greater than 0");
        salePrice = price;
    }

    function setMuv721Address(address addr) public onlyOwner {
        require(addr!=address(0),"can't set to null address");
        muv721Address = addr;
    }


    // mint function , check 
    //if maxsupply exhausted && mint per wallet breached && 
    //enough eth sent && public sale active &&  mint per transaction 
    function mintToken(uint256 amount)
        public
        payable
    {
        require(sale, "Sale is not started");
        require(
            amount <= 5 && amount >= 1,
            "mint per tras. range voilated"
        );
        require(amount.add(mintedCount) <= maxSupply, "Max Supply Limit reached");
        require(perWalletMintRecord[msg.sender].add(amount) <= perWalletMintLimit,"Mint Per Wallet Limit exceed");
        require(msg.value >= salePrice.mul(amount), "Not enough Matic sent");
        mintedCount = mintedCount.add(amount);
        perWalletMintRecord[msg.sender] = perWalletMintRecord[msg.sender].add(amount);
        _mint(msg.sender, maxSupply, amount, "");
    }

    // to withdraw funds from smart contract
    function withdrawFunds() public onlyOwner {

        payable(msg.sender).transfer(address(this).balance);
    }



    function airdropGiveaway(address to, uint256 amountToMint)
        public
        onlyOwner
        returns (uint256 tokId)
    {
        require(amountToMint.add(mintedCount) <= maxSupply, "Limit reached");
        mintedCount = mintedCount.add(amountToMint);
        _mint(to, maxSupply, amountToMint, "");
        return maxSupply;
    }

    function burnForRedeem(address account, uint256 amount) external {
        require(
            muv721Address == msg.sender,
            "You are not allowed to redeem"
        );
        _burn(account, maxSupply, amount);
    }
    
}