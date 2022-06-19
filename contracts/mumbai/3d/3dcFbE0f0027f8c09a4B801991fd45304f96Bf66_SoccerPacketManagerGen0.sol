/**
 *Submitted for verification at polygonscan.com on 2022-06-18
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/SC_SoccerPacketManagerGen0.sol



pragma solidity >=0.7.0 <0.9.0;


interface SoccerPlayersGen0Interface {
    function provideValues(address coach) external view returns (uint256 [5] memory);
    function packetMinted (uint256 id) external;
}


interface SoccerCoinInterface {
    function burnForAction(address _toWhom, uint256 _amount, uint256 _decimals) external;
    function balanceOf(address account) external view returns (uint256);
}


interface TeamBalanceInterface {
    function transferBalance() external payable;
}

contract SoccerPacketManagerGen0 is Ownable {


    address teamBalanceAddress = 0x834159F18931c2e30FBA5873574A2C9A862f10be;
    TeamBalanceInterface teamBalanceInterface = TeamBalanceInterface(teamBalanceAddress);

    address soccerCoinAddress = 0xc6aE78fBA7cCBB9A4455F9031d61C1014c06E20f;
    SoccerCoinInterface soccerCoinInterface = SoccerCoinInterface(soccerCoinAddress);


    address soccerPlayersGen0Address = 0x2f58fdDEBC37E02cf6962CCD9C86f979F0764712;
    SoccerPlayersGen0Interface soccerPlayersGen0Interface = SoccerPlayersGen0Interface(soccerPlayersGen0Address);


    uint256 [] public packetsPriceMATIC = [10000000000000000000 wei, 15000000000000000000 wei, 18000000000000000000 wei];
    uint256 [] public packetsPriceSOC = [20, 30, 36];
    uint256 public SOCPacketsDecimals = 18;


    function buyPacketMATIC(uint256 rarity) public payable {

        uint256 [5] memory data = soccerPlayersGen0Interface.provideValues(msg.sender);

        bool access = (data[0] == 1);
        uint256 totalSupply = data[1];
        uint256 maxSupply = data[2];
        uint256 raresMaxSupply = data[3];
        uint256 raresMinted = data[4];

        require(access);

        uint256 id;

        if(rarity == 0) {
            require(totalSupply + 4 <= maxSupply - raresMaxSupply - (totalSupply - raresMinted));
            require(msg.value >= packetsPriceMATIC[rarity]);

            for (uint256 i = 0; i < 4; i++){
                id = random(maxSupply - raresMaxSupply - (totalSupply - raresMinted));
                soccerPlayersGen0Interface.packetMinted(id);
            }

        } else if(rarity == 1) {
            require(raresMinted + 1 <= raresMaxSupply);
            require(totalSupply + 4 <= maxSupply - raresMaxSupply - (totalSupply - raresMinted));
            require(msg.value >= packetsPriceMATIC[rarity]);
            bool rareCatched = false;

            for (uint256 i = 0; i < 4; i++){
                if(random(raresMaxSupply+raresMinted) == 0 && !rareCatched){
                    rareCatched = true;
                    id = random(raresMaxSupply - raresMinted) + maxSupply - raresMaxSupply - (totalSupply - raresMinted);
                } else {
                    id = random(maxSupply - raresMaxSupply - (totalSupply - raresMinted));
                }
                soccerPlayersGen0Interface.packetMinted(id);
            }

        } else if(rarity == 2) {
            require(totalSupply + 3 <= maxSupply - raresMaxSupply - (totalSupply - raresMinted));
            require(raresMinted + 1 <= raresMaxSupply);
            require(msg.value >= packetsPriceMATIC[rarity]);

            for (uint256 i = 0; i < 3; i++){
                id = random(maxSupply - raresMaxSupply - (totalSupply - raresMinted));
                soccerPlayersGen0Interface.packetMinted(id);
            }
            id = random(raresMaxSupply - raresMinted) + maxSupply - raresMaxSupply - (totalSupply - raresMinted);
            soccerPlayersGen0Interface.packetMinted(id);
        }
        transferToBalance();
    }


    function buyPacketSOC(uint256 rarity) public {

        uint256 [5] memory data = soccerPlayersGen0Interface.provideValues(msg.sender);

        bool access = (data[0] == 1);
        uint256 totalSupply = data[1];
        uint256 maxSupply = data[2];
        uint256 raresMaxSupply = data[3];
        uint256 raresMinted = data[4];

        require(access);

        uint256 id;

        if(rarity == 0) {
            require(totalSupply + 4 <= maxSupply - raresMaxSupply - (totalSupply - raresMinted));
            require(soccerCoinInterface.balanceOf(msg.sender) >= packetsPriceSOC[rarity] * 10 ** SOCPacketsDecimals);

            for (uint256 i = 0; i < 4; i++){
                id = random(maxSupply - raresMaxSupply - (totalSupply - raresMinted));
                soccerPlayersGen0Interface.packetMinted(id);
            }

        } else if(rarity == 1) {
            require(raresMinted + 1 <= raresMaxSupply);
            require(totalSupply + 4 <= maxSupply - raresMaxSupply - (totalSupply - raresMinted));
            require(soccerCoinInterface.balanceOf(msg.sender) >= packetsPriceSOC[rarity] * 10 ** SOCPacketsDecimals);
            bool rareCatched = false;

            for (uint256 i = 0; i < 4; i++){
                if(random(raresMaxSupply+raresMinted) == 0 && !rareCatched){
                    rareCatched = true;
                    id = random(raresMaxSupply - raresMinted) + maxSupply - raresMaxSupply - (totalSupply - raresMinted);
                } else {
                    id = random(maxSupply - raresMaxSupply - (totalSupply - raresMinted));
                }
                soccerPlayersGen0Interface.packetMinted(id);
            }

        } else if(rarity == 2) {
            require(totalSupply + 3 <= maxSupply - raresMaxSupply - (totalSupply - raresMinted));
            require(raresMinted + 1 <= raresMaxSupply);
            require(soccerCoinInterface.balanceOf(msg.sender) >= packetsPriceSOC[rarity] * 10 ** SOCPacketsDecimals);

            for (uint256 i = 0; i < 3; i++){
                id = random(maxSupply - raresMaxSupply - (totalSupply - raresMinted));
                soccerPlayersGen0Interface.packetMinted(id);
            }
            id = random(raresMaxSupply - raresMinted) + maxSupply - raresMaxSupply - (totalSupply - raresMinted);
            soccerPlayersGen0Interface.packetMinted(id);
        }
        soccerCoinInterface.burnForAction(msg.sender, packetsPriceSOC[rarity], SOCPacketsDecimals);
    }


    // Utils
    function random(uint256 maxValue) internal view returns (uint256) {  
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % maxValue;
    }


    // Settings Functions
    function setPacketPriceMATIC (uint256 [] memory prices) public onlyOwner {
        packetsPriceMATIC = prices;
    }


    function setPacketPriceSOC (uint256 [] memory prices, uint256 decimals) public onlyOwner {
        packetsPriceSOC = prices;
        SOCPacketsDecimals = decimals;
    }


    // ########## Manage Finance ##########
    function transferToBalance() internal {
        teamBalanceInterface.transferBalance{value: (address(this).balance)}();
    }
}