// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";

contract MintERC1155 is ERC1155, Ownable, ERC1155Burnable {
    using Strings for uint256;
    ERC1155Burnable mintPassContract;
    IERC20 token;
    IERC1155 token1155;

    string name;
    string symbol;

    string baseURI;
    string public baseExtension = ".json";
    bool public paused;

    uint256 public cost = 1 * 10**18;
    uint256 public totalPaid;

    uint256 private tokenIds;

    mapping(address => uint256[]) adrToIds;

    mapping(uint256 => Item) private items;

    struct wl {
        uint256 amount;
        uint256 cost;
    }

    mapping(address => uint256) public amountsNFT;
    mapping(address => uint256) public amountsNFTMinted;
    mapping(address => uint256) publicMinted;
    /*mapping(address => uint256[]) public idOfUser;*/

    mapping(uint256 => Admin) idToAdmin;
    mapping(address => uint256) adrToId;
    mapping(address => bool) isAdmin;
    uint256 public adminAmount;
    address[] private admins;

    struct Admin {
        uint256 id;
        address user;
        bool isAdmin;
    }

    uint256 public nftAmountPerUser;

    uint256 public maxAmount = 7500;
    uint256 public currentAmount;

    struct Item {
        uint256 id;
        address creator;
        uint256 quantity;
        address holder;
    }

    struct drop {
        uint256 totalSupply;
        uint256 minted;
        uint256 startTime;
        uint256 duration;
    }

    mapping(uint256 => drop) idToDrop;
    uint256 public totalDrop;

    mapping(uint256 => drop) idToMintPassDrop;
    uint256 public totalMintPassDrop;

    uint256 nextDropStartTime;
    uint256 nextDropDuration;
    uint256 nextDropAmount;

    constructor(
        uint256 cost_,
        string memory uri_,
        uint256 nftAmountPerUser_,
        string memory name_,
        string memory symbol_,
        address mintPassAddress,
        address tokenAddress
    ) ERC1155(uri_) {
        cost = cost_;

        baseURI = uri_;
        paused = true;
        nftAmountPerUser = nftAmountPerUser_;
        name = name_;
        symbol = symbol_;
        mintPassContract = ERC1155Burnable(mintPassAddress);
        token = IERC20(tokenAddress);
        token1155 = IERC1155(mintPassAddress);
    }

    function changeTokenContract(address newToken) external onlyOwner {
        token = IERC20(newToken);
    }

    function changeMintPassContract(address newTokenContract)
    external
    onlyOwner
    {
        mintPassContract = ERC1155Burnable(newTokenContract);
        token1155 = ERC1155(newTokenContract);
    }

    function freeClaimPass(uint256 amount) external {
        require(!paused, "mint is paused");

        require(currentAmount + amount <= maxAmount, "Amount is exceeded");

        address user = msg.sender;

        require(
            token1155.balanceOf(user, 1) > 0,
            "You don't have freeClaimPass key"
        );

        mintPassContract.burn(msg.sender, 1, amount);

        for (uint256 i; i < amount; i++) {
            _mint(msg.sender, tokenIds, 1, "");
            currentAmount++;
            if (!isInArray(adrToIds[msg.sender], tokenIds)) {
                adrToIds[msg.sender].push(tokenIds);
            }

            items[tokenIds] = Item(tokenIds, msg.sender, 1, msg.sender);

            amountsNFT[msg.sender]++;
            amountsNFTMinted[msg.sender]++;
            //idOfUser[msg.sender].push(tokenIds);

            tokenIds++;
        }
    }

    function mintPass(uint256 amount) external {
        require(!paused, "mint is paused");

        require(currentAmount + 1 <= maxAmount);

        require(
            block.timestamp > idToMintPassDrop[totalDrop].startTime &&
            block.timestamp <
            idToMintPassDrop[totalDrop].startTime +
            idToMintPassDrop[totalDrop].duration,
            "Not time to mint"
        );
        require(
            idToMintPassDrop[totalDrop].minted + amount <=
            idToMintPassDrop[totalDrop].totalSupply,
            "Supply is exceeded"
        );

        address user = msg.sender;

        require(
            token1155.balanceOf(user, 0) > 0,
            "You don't have mintPass key"
        );

        mintPassContract.burn(msg.sender, 0, amount);
        token.transferFrom(
            msg.sender,
            address(this),
            (cost * amount * 80) / 100
        );
        for (uint256 i; i < amount; i++) {
            _mint(msg.sender, tokenIds, 1, "");
            currentAmount++;
            if (!isInArray(adrToIds[msg.sender], tokenIds)) {
                adrToIds[msg.sender].push(tokenIds);
            }

            items[tokenIds] = Item(tokenIds, msg.sender, 1, msg.sender);

            amountsNFT[msg.sender]++;
            amountsNFTMinted[msg.sender]++;

            tokenIds++;
            idToMintPassDrop[totalDrop].minted++;
        }
    }

    function mint(address to, uint256 amount) external payable {
        require(!paused, "mint is paused");

        //require(blacklist[msg.sender] == false, "you are in blacklist");
        require(currentAmount + amount <= maxAmount);

        require(
            publicMinted[msg.sender] + amount <= nftAmountPerUser,
            "NFT per user is exceeded"
        );
        require(
            block.timestamp > idToDrop[totalDrop].startTime &&
            block.timestamp <
            idToDrop[totalDrop].startTime + idToDrop[totalDrop].duration,
            "Not time to mint"
        );
        require(
            idToDrop[totalDrop].minted + amount <=
            idToDrop[totalDrop].totalSupply,
            "Supply is exceeded"
        );
        for (uint256 i; i < amount; i++) {
            _mint(to, tokenIds, 1, "");
            currentAmount++;
            if (!isInArray(adrToIds[to], tokenIds)) {
                adrToIds[to].push(tokenIds);
            }

            items[tokenIds] = Item(tokenIds, msg.sender, 1, to);

            amountsNFT[to]++;
            amountsNFTMinted[msg.sender]++;
            publicMinted[msg.sender]++;
            //idOfUser[msg.sender].push(tokenIds);

            tokenIds++;
            idToDrop[totalDrop].minted++;
        }
    }

    function makeMintPassDrop(
        uint256 amount,
        uint256 startTime,
        uint256 duration
    ) external onlyOwner {
        totalMintPassDrop++;
        idToMintPassDrop[totalDrop] = drop(amount, 0, startTime, duration);
    }

    function makeDrop(
        uint256 amount,
        uint256 startTime,
        uint256 duration
    ) external onlyOwner {
        totalDrop++;
        idToDrop[totalDrop] = drop(amount, 0, startTime, duration);
    }

    function nameCollection() external view returns (string memory) {
        return name;
    }

    function symbolCollection() external view returns (string memory) {
        return symbol;
    }

    function setNameCollection(string memory name_) external onlyOwner {
        name = name_;
    }

    function changePauseStatus() external onlyOwner {
        paused = !paused;
    }

    function changeMaxAmount(uint256 newMaxAMount) external onlyOwner {
        require(newMaxAMount >= currentAmount);
        maxAmount = newMaxAMount;
    }

    function changeNftAmountPerUser(uint256 newAmount) external onlyOwner {
        nftAmountPerUser = newAmount;
    }

    function checkUserIds() external view returns (uint256[] memory) {
        return adrToIds[msg.sender];
    }

    /*function checkItems() external view returns (Item memory){
        return(items[msg.sender]);
    }*/

    /*function totalSupply() external view returns (uint256) {
        return tokenIds;
    }*/

    function checkUserMintedAmount() external view returns (uint256) {
        return amountsNFTMinted[msg.sender];
    }

    function checkUserActualAmount() external view returns (uint256) {
        return amountsNFT[msg.sender];
    }

    function _ownerOf(uint256 tokenId) internal view returns (bool) {
        return balanceOf(msg.sender, tokenId) != 0;
    }

    function isInArray(uint256[] memory Ids, uint256 id)
    internal
    pure
    returns (bool)
    {
        for (uint256 i; i < Ids.length; i++) {
            if (Ids[i] == id) {
                return true;
            }
        }
        return false;
    }

    function uri(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(tokenId <= tokenIds);

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).

        return
        bytes(baseURI).length > 0
        ? string(
            abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
        )
        : "";
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable {
        //require(blacklist[msg.sender] == false, "User blacklisted");
        for (uint256 i; i < amounts.length; i++) {
            require(amounts[i] == 1, "amount has to be 1");
        }
        require(from == msg.sender, "not allowance");

        _safeBatchTransferFrom(from, to, ids, amounts, "");
        //adrToIds[msg.sender]
        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            for (uint256 j; j < ids.length; j++) {
                if (adrToIds[msg.sender][i] == ids[j]) {
                    adrToIds[to].push(ids[j]);
                    remove(i, msg.sender);
                    items[ids[j]].holder = to;
                }
            }
        }
        amountsNFT[msg.sender] -= ids.length;
        amountsNFT[to] += ids.length;
    }

    function transfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external payable {
        //require(blacklist[msg.sender] == false, "User blacklisted");
        require(from == msg.sender, "not allowance");
        require(amount == 1, "amount has to be 1");

        _safeTransferFrom(from, to, id, amount, "");
        items[id].holder = to;

        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            if (adrToIds[msg.sender][i] == id) {
                adrToIds[to].push(id);
                remove(i, msg.sender);
            }
        }
        amountsNFT[msg.sender]--;
        amountsNFT[to]++;
    }

    function remove(uint256 index, address user)
    internal
    returns (uint256[] memory)
    {
        //if (index >= adrToIds[msg.sender].length) return ;

        for (uint256 i = index; i < adrToIds[user].length - 1; i++) {
            adrToIds[user][i] = adrToIds[user][i + 1];
        }
        delete adrToIds[user][adrToIds[user].length - 1];
        adrToIds[user].pop();
        return adrToIds[user];
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}

    function isInArrayMarket(address[] memory markets, address adr)
    internal
    pure
    returns (bool)
    {
        for (uint256 i; i < markets.length; i++) {
            if (markets[i] == adr) {
                return true;
            }
        }
        return false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        //require(!blacklist[to], "Buyer is in blacklist");
        /*require(
            isInArrayMarket(marketplaces, msg.sender),
            "This function is only for our marketplace"
        );*/
        _safeTransferFrom(from, to, id, amount, data);
        adrToIds[to].push(id);
        for (uint256 i; i < adrToIds[from].length; i++) {
            if (adrToIds[from][i] == id) {
                remove(i, from);
            }
        }
        items[id].holder = to;
        amountsNFT[from]--;
        amountsNFT[to]++;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseExtension(string memory _newBaseExtension)
    public
    onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function addAdmin(address admin) external onlyOwner {
        //require(blacklist[msg.sender] == false, "User blacklisted");
        require(isAdmin[admin] != true, "Already admin");
        adminAmount++;
        idToAdmin[adminAmount] = Admin(adminAmount, admin, true);
        adrToId[admin] = adminAmount;
        admins.push(admin);
        isAdmin[admin] = true;
    }

    function showAdmins() external view returns (address[] memory) {
        return (admins);
    }

    function deleteAdmin(address admin) external onlyOwner {
        //require(blacklist[admin] == false, "User blacklisted");
        require(
            idToAdmin[adrToId[admin]].isAdmin == true,
            "User is not in admin list"
        );
        idToAdmin[adrToId[admin]].isAdmin = false;
        for (uint256 i; i < admins.length; i++) {
            if (admins[i] == idToAdmin[adrToId[admin]].user) {
                removeAdmin(i);
                break;
            }
        }
        adminAmount--;
        isAdmin[admin] = false;
    }

    function removeAdmin(uint256 index) internal returns (address[] memory) {
        //if (index >= adrToIds[msg.sender].length) return ;

        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    function showItems(uint256 number) external view returns (Item memory) {
        require(items[number].id <= tokenIds);
        return items[number];
    }

    function checkDropInfo(uint256 number) external view returns (drop memory) {
        require(number < totalDrop, "drop number doesn't exist");
        return idToDrop[number];
    }

    function checkMintPassDropInfo(uint256 number)
    external
    view
    returns (drop memory)
    {
        require(number < totalMintPassDrop, "drop number doesn't exist");
        return idToMintPassDrop[number];
    }

    //function changeParametersWhitelist(address user, )

    function availableNFTs()
    external
    view
    returns (uint256 amount, uint256 costForMint)
    {
        return (nftAmountPerUser - amountsNFTMinted[msg.sender], cost);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
        }("");
        require(success);
    }
}