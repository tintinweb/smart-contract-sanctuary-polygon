//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC1155_Drop.sol";
import "./Strings.sol";

contract NFTES_Drop is ERC1155_Drop {
    //NFT category
    // NFT Description & URL
    string data = "";

    //NFTs distribution w.r.t Probabilities
    //Max probability of Diamond(id=0) = 0.5%
    //Max probability of Gold(id=1) = 10%
    //Max probability of Silver(id=2) = 85%
    uint8[20] private nums = [
        0,
        1,
        1,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2
    ];

    uint256 totalNFTsMinted; //Total NFTs
    uint256 numOfCopies; //A user can mint only 1 NFT
    uint256 mintFees;

    //Initial Minting
    uint256 Diamond;
    uint256 Gold;
    uint256 Silver;

    //owner-NFT-ID Mapping
    //Won NFTs w.r.t Addresses
    struct nft_Owner {
        uint256[] owned_Dropsite_NFTs;
    }

    mapping(address => nft_Owner) dropsite_NFT_Owner;

    //payments Mapping
    mapping(address => uint256) deposits;
    modifier OnlyOwner() {
        require(_msgSender() == Owner, "Only NFT-ES Owner can Access");
        _;
    }

    //Pausing and activating the contract
    modifier contractIsNotPaused() {
        require(isPaused == false, "Dropsite is not Opened Yet.");
        _;
    }
    modifier mintingFeeIsSet() {
        require(mintFees!=0, "Owner Should set mint Fee First");
        _;
    }
    bool public isPaused = true;
    address payable public Owner;
    string private _name;

    constructor(string memory name) {
        _name = name;
        Owner = payable(msg.sender);

        totalNFTsMinted = 0; //Total NFTs Minted
        numOfCopies = 1; //A user can mint only 1 NFT
        Diamond = 0;
        Gold = 0;
        Silver = 0;
    }

    //Check NFTs issued to an address
    function returnOwner(address addr)
        public
        view
        contractIsNotPaused
        returns (uint256[] memory)
    {
        return dropsite_NFT_Owner[addr].owned_Dropsite_NFTs;
    }

    //To Check No of issued NFTs Category Wise
    function checkMintedCategoryWise()
        public
        view
        OnlyOwner
        contractIsNotPaused
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (Diamond, Gold, Silver);
    }

    function setMintFee(uint256 _mintFee) public OnlyOwner contractIsNotPaused {
        mintFees = _mintFee;
    }

    function getMintFee()
        public
        view
        OnlyOwner
        contractIsNotPaused
        returns (uint256)
    {
        return mintFees;
    }

    //To Check total Minted NFTs
    function checkTotalMinted() public view OnlyOwner returns (uint256) {
        return totalNFTsMinted;
    }

    function stopDropsite() public OnlyOwner {
        require(isPaused == false, "Dropsite is already Stopped");
        isPaused = true;
    }

    function openDropsite() public OnlyOwner {
        require(isPaused == true, "Dropsite is already Running");
        isPaused = false;
    }

    //To WithDraw All Ammount from Contract to Owners Address or any other Address
    function withDraw(address payable to) public payable OnlyOwner {
        uint256 Balance = address(this).balance;
        require(Balance > 0 wei, "Error! No Balance to withdraw");
        to.transfer(Balance);
    }

    //To Check Contract Balance in Wei
    function contractBalance() public view OnlyOwner returns (uint256) {
        return address(this).balance;
    }

    //Random Number to Select an item from nums Array(Probabilities)
    //Will return an index b/w 0-20
    function random() internal view returns (uint256) {
        // Returns 0-20
        //To Achieve maximum level of randomization!
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    ((block.timestamp) +
                        totalNFTsMinted +
                        Silver +
                        Gold +
                        Diamond),
                    msg.sender,
                    Owner
                )
            )
        ) % 20;
        return randomnumber;
    }

    //random number will be generated which will be the index to nums array.
    //The number on that index will be considered as an nftID and will be alloted to the minter(user).
    function updateConditions(uint256 index)
        internal
        contractIsNotPaused
        returns (uint256)
    {
        uint256 nftId = nums[index];
        // if nftID is 0, and less than 51 so 50 MAX - Diamond Category
        if (nftId == 0 && Diamond < 50) {
            Diamond++;
            data = string(
                abi.encodePacked("Diamond_", Strings.toString(Diamond))
            );
            return nftId;
            // if nftID is 0 or 1 and Diamond is more than 150, it will go there in Gold Category
        } else if (nftId <= 1 && Gold < 100) {
            Gold++;
            data = string(abi.encodePacked("Gold_", Strings.toString(Gold)));
            return nftId;
            // if any of the above conditions are filled it will mint silver if enough silver available
        } else if (nftId <= 2 && Silver <= 850) {
            Silver++;
            data = data = string(
                abi.encodePacked("Silver_", Strings.toString(Silver))
            );
            return nftId;
        } else {
            //if nft ID is either 1 or 2, but Slots in Gold or Diamond are remaining,
            //First Gold category will be filled then Diamond

            if (Gold < 100) {
                nftId = 1;
                Gold++;
                data = string(
                    abi.encodePacked("Gold_", Strings.toString(Gold))
                );

                return nftId;
            } else {
                nftId = 0;
                Diamond++;
                data = string(
                    abi.encodePacked("Diamond_", Strings.toString(Diamond))
                );
                return nftId;
            }
        }
    }

    function randomMinting(address user_addr)
        public
        payable
        OnlyOwner
        contractIsNotPaused
        returns (uint256, string memory)
    {
        // nftId = random(); // we're assuming that random() returns only 0,1,2
        uint256 index = random();
        uint256 nftId = updateConditions(index);
        _mint(user_addr, nftId, numOfCopies, data);
        totalNFTsMinted++;
        dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs.push(nftId);
        return (nftId, string(data));
    }

    //Random minting after Fiat Payments
    function fiatRandomMint (address user_addr, uint256 noOfMints)
        public
        OnlyOwner
        contractIsNotPaused
        mintingFeeIsSet
        returns (uint256[] memory)
    {
        require(noOfMints < 4 && noOfMints > 0, "You can mint 1-3 NFTs");
        require(totalNFTsMinted < 1000, "Max Minting Limit reached");
        require(mintFees != 0, "Mint Fee Not Set");
        for (uint256 i = 0; i < noOfMints; i++) {
            randomMinting(user_addr);
        }
        return dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs;
    }

    //MATIC Amount will be deposited
    function depositAmount(address payee, uint256 amountToDeposit) internal {
        deposits[payee] += amountToDeposit;
    }

    //Random minting after Crypto Payments
    function cryptoRandomMint(address user_addr, uint256 noOfMints)
        public
        payable
        contractIsNotPaused
        mintingFeeIsSet
        returns (uint256[] memory)
    {
        require(noOfMints < 4 && noOfMints > 0, "You can mint 1-3 NFTs");
        require(totalNFTsMinted < 1000, "Max Minting Limit reached");
        require(mintFees != 0, "Mint Fee Not Set");
        require(msg.value == mintFees * noOfMints, "Not Enough Balance");

        for (uint256 i = 0; i < noOfMints; ++i) {
            randomMinting(user_addr);
        }
        depositAmount(_msgSender(), msg.value);
        return dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs;
    }
}