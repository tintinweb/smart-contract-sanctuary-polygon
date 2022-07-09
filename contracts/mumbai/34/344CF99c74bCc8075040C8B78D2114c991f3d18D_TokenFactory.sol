// SPDX-License-Identifier: MIT
// NFTZero Contracts v0.0.1

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";

contract TokenFactory is IOmniApp {

    event Minted(address collAddr, address rec);
    event Paid(address rec);
    event Locked(address rec, uint256 amount, address asset);
    event Refunded(address rec);
    event OnResponse(address rec, address cre, uint256 amount);
    event NewRefund(address collAddr, address spender);
    event InvalidPrice(address collAddr, address spender, uint256 paid);
    event InvalidCreator(address collAddr, address cre);

    IOmnichainRouter public omnichainRouter;
    address[] public assets;
    mapping (address => mapping (string => mapping (address => uint256))) public refunds;
    mapping (address => mapping (string => uint256)) public mints;
    mapping (address => address[]) public ownedCollections;
    string public chainName;
    mapping(string => address) public chainToUA;
    address private _owner;
    address private _treasury;

    constructor(IOmnichainRouter _router) {
        _owner = msg.sender;
        chainName = "Polygon";
        _treasury = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        omnichainRouter = _router;
    }

    function addBaseAsset(address asset) external {
        require(msg.sender == _owner);
        assets.push(asset);
    }

    function setUA(string memory _chainName, address chainUA) external {
        require(msg.sender == _owner);
        chainToUA[_chainName] = chainUA;
    }

    function isUA(string memory _chainName, address chainUA) public view returns (bool) {
        return chainToUA[_chainName] == chainUA;
    }

    function mintToken(
        string memory _dstChainName,
        address coll,
        uint256 mintPrice,
        address creator,
        uint256 gas
    ) public payable {
        require(bytes(_dstChainName).length > 0 && coll != address(0));
        if (keccak256(bytes(_dstChainName)) == keccak256(bytes(chainName))) {
            IOmniERC721 omniNft = IOmniERC721(coll);
            uint256 price = omniNft.getMintPrice();
            if (price > 0) {
                payOnMint(price, msg.sender, omniNft.getCreator(), false);
            }
            omniNft.mint(msg.sender);
            ownedCollections[msg.sender].push(coll);
            emit Minted(coll, msg.sender);
            return;
        }
        if (mintPrice > 0) {
            payOnMint(mintPrice, msg.sender, address(this), true);
        }
        bytes memory payload = _getMintPayload(coll, mintPrice, creator);
        _omniAction(payload, _dstChainName, gas);
    }

    function omReceive(bytes calldata _payload, address srcUA, string memory srcChain) external override {
        require(isUA(srcChain, srcUA));
        (uint256 act, address coll, bool minted, uint256 paid, address rec, address cre) = abi.decode(_payload, (uint256, address, bool, uint256, address, address));
        if (act != 1) {
            pay(rec, cre, paid, minted);
            return;
        }
        IOmniERC721 nft = IOmniERC721(coll);
        uint256 price = nft.getMintPrice();
        uint256 supply = nft.getTotalSupply();
        if (price > 0 && (supply > 0 && nft.getMintedCount() >= supply)) {
            emit NewRefund(coll, rec);
            refunds[coll][srcChain][rec] += price;
            return;
        }
        if (cre != nft.getCreator()) {
            emit InvalidCreator(coll, cre);
            return;
        }

        if (price > 0 && paid < price) {
            emit InvalidPrice(coll, rec, paid);
            return;
        }

        nft.mint(rec);
        ownedCollections[rec].push(coll);
        emit Minted(coll, rec);
        mints[coll][srcChain]++;
    }

    function refund(address coll, string memory _dstChainName, uint256 gas) external payable {
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 amount = refunds[coll][_dstChainName][msg.sender];
        require(collection.getMintPrice() > 0 && amount > 0);
        refunds[coll][_dstChainName][msg.sender] = 0;
        _resAction(_getResPayload(coll, false, amount), _dstChainName, gas);
    }

    function getEarned(address coll, string memory _dstChainName, uint256 gas) external payable {
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 price = collection.getMintPrice();
        uint256 amount = mints[coll][_dstChainName] * price;
        require(price > 0 && amount > 0 && msg.sender == collection.getCreator());
        mints[coll][_dstChainName] = 0;
        _resAction(_getResPayload(coll, true, amount), _dstChainName, gas);
    }

    function _omniAction(bytes memory payload, string memory _dstChainName, uint256 gas) private {
        omnichainRouter.send{value : msg.value}(_dstChainName, chainToUA[_dstChainName], payload, gas, msg.sender);
    }

    function _resAction(bytes memory payload, string memory _dstChainName, uint256 gas) private {
        _omniAction(payload, _dstChainName, gas);
    }

    function payOnMint(uint256 price, address spender, address rec, bool locked) internal {
        address asset = assets[0]; // TODO: Set asset per collection
        bool isSupported = isAssetSupported(asset);
        require(isSupported);
        IERC20 erc = IERC20(asset);
        require(erc.allowance(spender, address(this)) >= price);

        if (locked) {
            erc.transferFrom(spender, rec, price);
            emit Locked(rec, price, asset);
            return;
        }
        erc.transferFrom(spender, rec, price * 98 / 100);
        erc.transferFrom(spender, _treasury, price * 2 / 100);
        emit Paid(rec);
    }

    function pay(address rec, address cre, uint256 price, bool minted) private {
        emit OnResponse(rec, cre, price);

        if (price == 0) {
            return;
        }

        IERC20 erc = IERC20(assets[0]); // TODO: Set asset per collection and get from it
        if (minted) {
            erc.transfer(cre, price * 98 / 100);
            erc.transfer(_treasury, price * 2 / 100);
            emit Paid(cre);
            return;
        }
        erc.transfer(rec, price);
        emit Refunded(rec);
    }

    function unlockPayment(address coll, string memory _chainName, bool minted, address rec) external {
        require(msg.sender == _owner);
        address asset = assets[0]; // TODO: Asset per collection
        bool isSupported = isAssetSupported(asset);
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 price = collection.getMintPrice();
        uint256 amount = minted ? (mints[coll][_chainName] * price) : (refunds[coll][_chainName][rec]);
        uint256 startDate = collection.getFrom() > 0 ? collection.getFrom() : collection.getCreatedAt();
        require(isSupported && price > 0 && amount > 0 && startDate <= (block.timestamp - 14 days));
        IERC20 erc = IERC20(asset);
        erc.transfer(rec, amount);

        if (minted) {
            emit Paid(rec);
            return;
        }
        emit Refunded(rec);
    }

    function isAssetSupported(address asset) public view returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (asset == assets[i]) {
                return true;
            }
        }
        return false;
    }

    function _getMintPayload(address coll, uint256 price, address cre) private view returns (bytes memory) {
        return abi.encode(1, coll, true, price, msg.sender, cre);
    }

    function _getResPayload(address coll, bool minted, uint256 amount) private view returns (bytes memory) {
        return abi.encode(2, coll, minted, amount, msg.sender, msg.sender);
    }

    receive() external payable {}
}

pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner) external;
    function getTotalSupply() external view returns (uint256);
    function getMintPrice() external view returns (uint256);
    function getMintedCount() external view returns (uint256);
    function getCreator() external view returns (address);
    function getCreatedAt() external view returns (uint256);
    function getFrom() external view returns (uint256);
    function getAddress() external view returns (address);
    function getDetails() external view returns (string memory, address, uint256, uint256, uint256);
    function setFileURI(string memory fileURI) external;
    function setDates(uint256 _from, uint256 _to) external;
    function addMetadataURIs(string[] memory _metadataURIs) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.7;

interface IOmniApp {
    function omReceive(bytes calldata _payload, address srcUA, string memory srcChain) external;
}

pragma solidity ^0.8.7;

interface IOmnichainRouter {
    function send(string memory dstChainName, address dstUA, bytes memory _fnData, uint gas, address origin) external payable;
}