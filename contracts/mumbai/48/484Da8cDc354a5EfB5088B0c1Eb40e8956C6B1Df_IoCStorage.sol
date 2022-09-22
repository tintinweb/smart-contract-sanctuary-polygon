// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReputationRouter.sol";

/**
 * @author Vakhtanh Chikhladze
 * @dev Storage, that store Indicator of Comprometations (IoC) on Solidity compatible blockchains
 */
contract IoCStorage {

    /**
     * @dev address of reputation router
     */
    ReputationRouter public reputationRouter;

    /**
     * @dev array of ioc hashes
     */
    bytes32[] public iocHashes;

    /**
     * @dev iocHash => ioc info
     */
    mapping(bytes32 => IoCInfo) public iocInfo;

    /**
     * @dev iocHash => endpointAddress => reportHash
     */
    mapping(bytes32 => mapping (address => bytes32)) public reports;

    struct IoCInfo {
        string iocData;
        address iocCreator;
        address[] reporters;
    }

    modifier onlyReputationRouter() {
        require(msg.sender == address(reputationRouter), "IoCStorage: msg.sender is not reputationRouter");
        _;
    }
    
    event AddIoC(address indexed endpoint, bytes32 indexed iocHash);
    
    event ReportIoC(address indexed endpoint, bytes32 indexed iocHash, bytes32 indexed reportHash);

    event MintIoC(address indexed endpoint, bytes32 indexed iocHash, string ioc);

    function initialize(address reputationRouter_) public {
        require(address(reputationRouter) == address(0), "IoCStorage: initialized");
        reputationRouter = ReputationRouter(reputationRouter_);
        require(msg.sender == reputationRouter.shareholder() || msg.sender == reputationRouter_, "ReputationLock: invalid reputation router address");
    }
 
    function addIoC(bytes32 iocHash, address endpoint) public onlyReputationRouter {
        IoCInfo memory _iocInfo;
        require(_iocInfo.iocCreator == address(0), "IoCStorage: ioc exist");
        _iocInfo.iocCreator = endpoint;
        iocInfo[iocHash] = _iocInfo;
        iocHashes.push(iocHash);
        emit AddIoC(endpoint, iocHash);
    }

    function reportIoC(bytes32 iocHash, address endpoint, bytes32 reportHash) public onlyReputationRouter {
        require(reports[iocHash][endpoint] == bytes32(0), "IoCStorage: ioc already reported");
        reports[iocHash][endpoint] = reportHash;
        IoCInfo storage _iocInfo = iocInfo[iocHash];
        _iocInfo.reporters.push(endpoint);
        emit ReportIoC(endpoint, iocHash, reportHash);
    }

    function mintIoC(bytes32 iocHash, address endpoint, string memory iocData) public onlyReputationRouter {
        IoCInfo storage _iocInfo = iocInfo[iocHash];
        require(bytes(iocData).length > 0, "IoCStorage: ioc data cannot be empty string");
        require(_iocInfo.iocCreator == endpoint, "IoCStorage: endpoint is not iocCreator");
        require(bytes(_iocInfo.iocData).length == 0, "IoCStorage: ioc already minted");
        _iocInfo.iocData = iocData;
        emit MintIoC(endpoint, iocHash, iocData);
    }

    /***** VIEW FUNCTIONS *****/

    /**
     * @dev returns length of array `iocHashes`
     */
    function getIoCHashesLength() public view returns (uint256) {
        return iocHashes.length;
    }

    /**
     * @dev returns ioc by provided `iocHashId`
     * @param iocHashId - id of ioc. The value from 0 to length of array `iocHashes`
     */
    function getIoCHash(uint256 iocHashId) public view returns (bytes32) {
        return iocHashes[iocHashId];
    }

    /**
     * @dev return ioc info
     */
    function getIoCInfo(bytes32 iocHash) public view returns (string memory iocData, address iocCreator, address[] memory reporters) {
        IoCInfo memory _iocInfo = iocInfo[iocHash];
        return (_iocInfo.iocData, _iocInfo.iocCreator, _iocInfo.reporters);
    }

    function getIoCReporter(bytes32 iocHash, uint256 reporterId) public view returns (address reporter) {
        IoCInfo memory _iocInfo = iocInfo[iocHash];
        uint256 reportsLength = _iocInfo.reporters.length;
        require(reporterId < reportsLength, "IoCStorage: read unexisted reporter");
        return _iocInfo.reporters[reporterId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IReputationRouter.sol";
import "./ReputationToken.sol";
import "./ReputationLock.sol";
import "./IoCStorage.sol";
import "./IoC.sol";

contract ReputationRouter is IReputationRouter {

    /**
     * @dev address of shareholder
     */
    address public shareholder;
    
    /**
     * @dev address of reputation token
     */
    ReputationToken public reputationToken;

    /**
     * @dev address of reputation lock smart contract
     */
    ReputationLock public reputationLock;

    /**
     * @dev address of ioc storage
     */
    IoCStorage public iocStorage;

    /**
     * @dev address of ioc storage
     */
    IoC public ioc;

    /**
     * @dev amount of Reputation token per IoC 
     */
    uint256 public reputationPerIoC;

     /**
     * @dev minimal amount of Reputation token per reporting IoC 
     */
    uint256 public minReputationPerIoC;

    /**
     * @dev distribution of reward 
        Example: distribution = [50, 25, 13, 12]. The sum in this array equal 50+25+13+12 = 100
        This may be defined by first will earn 50/100 of reward, second will earn 25/100 of reward,
        third will earn 13/100 of reward, fourth will earn 12/100 of reward. 
     */
    uint256[] public distribution;

    /**
     * @dev sum of elements in array `distribution`
     */
    uint256 public distributionSum;

    uint256 public minReportsRequired;

    modifier onlyShareholder {
        require(msg.sender == shareholder, "ReputationRouter: msg.sender is not shareholder");
        _;
    }   

    /***** SHAREHOLDER FUNCTIONS *****/

    function initialize(
        address reputationToken_, 
        address reputationLock_,
        address iocStorage_,
        address ioc_,
        uint256 totalSupplyCap_
    ) public {
        require(
            address(reputationToken) == address(0) && 
            address(reputationLock) == address(0) && 
            address(iocStorage) == address(0) && 
            address(ioc) == address(0), 
            "ReputationRouter: initialized"
        );

        shareholder = msg.sender;

        reputationToken = ReputationToken(reputationToken_);
        reputationLock = ReputationLock(reputationLock_);
        iocStorage = IoCStorage(iocStorage_);
        ioc = IoC(ioc_);

        reputationToken.initialize(address(this), totalSupplyCap_);
        reputationLock.initialize(address(this));
        iocStorage.initialize(address(this));
        ioc.initialize(address(this));

        reputationToken.mint(address(reputationLock), totalSupplyCap_);
        uint256 reputationPerIoC_ = 1e18; 
        uint256 minReputationPerIoC_ = 1e15;
        uint256[] memory distribution_ = new uint256[](4);
        distribution_[0] = 50;
        distribution_[1] = 25;
        distribution_[2] = 13;
        distribution_[3] = 12;
        uint256 minReportsRequired_ = 4;
        setParams(reputationPerIoC_, minReputationPerIoC_, distribution_, minReportsRequired_);
    }

    function setParams(
        uint256 reputationPerIoC_,
        uint256 minReputationPerIoC_,
        uint256[] memory distribution_,
        uint256 minReportsRequired_
    ) public {
        setReputationPerIoC(reputationPerIoC_);
        setMinReputationPerIoC(minReputationPerIoC_);
        setDistribution(distribution_);
        setMinReportsRequired(minReportsRequired_);
    }

    function setReputationPerIoC(uint256 reputationPerIoC_) public onlyShareholder {
        reputationPerIoC = reputationPerIoC_;
    }

    function setMinReputationPerIoC(uint256 minReputationPerIoC_) public onlyShareholder {
        minReputationPerIoC = minReputationPerIoC_;
    }

    function setDistribution(uint256[] memory distribution_) public onlyShareholder {
        uint256 distribution_Length = distribution_.length;
        uint256 _distributionSum = 0;
        for(uint256 i = 0; i < distribution_Length;){
            _distributionSum += distribution_[i];
            unchecked { ++i; }
        }
        distribution = distribution_;
        distributionSum = _distributionSum;
    }

    function setMinReportsRequired(uint256 minReportsRequired_) public onlyShareholder {
        minReportsRequired = minReportsRequired_;
    }

    function transferShareholder(address newShareholder) public onlyShareholder {
        shareholder = newShareholder;
    }

    /***** ENDPOINT FUNCTIONS *****/

    function addIoC(bytes32 iocHash, bytes memory shareholderSignature) public override {
        require(
            verify(
                msg.sender, // endpoint adder address: 20 bytes 
                IReputationRouter.addIoC.selector, // addIoC selector: 0xeee20731
                iocHash,    // iocHash: any 32 bytes
                bytes(""),  // extraData: 0x
                shareholderSignature // signature: 65 bytes
            ),
            "ReputationRouter: addIoC invalid signature"
        );
        iocStorage.addIoC(iocHash, msg.sender);
        reputationLock.addIoC(iocHash, msg.sender);
    }

    function reportIoC(bytes32 iocHash, bytes32 reportHash, bytes memory shareholderSignature) public override {
        require(
            verify(
                msg.sender, // endpoint reporter address
                IReputationRouter.reportIoC.selector, // reportIoC selector: 0xeb6bfde9
                iocHash, // ioc hash: any 32 bytes
                abi.encodePacked(reportHash), // extraData is report hash: any 32 bytes
                shareholderSignature // signature: 65 bytes
            ),
            "ReputationRouter: reportIoC invalid signature"
        );
        iocStorage.reportIoC(iocHash, msg.sender, reportHash);
        reputationLock.reportIoC(iocHash, msg.sender);

    }
    
    function release(bytes32 iocHash) public override {
        reputationLock.release(iocHash, msg.sender);
    }

    function mintIoC(bytes32 iocHash, string memory iocData, bytes memory shareholderSignature) public override {
        require(
            verify(
                msg.sender, // endpoint addrer address
                IReputationRouter.mintIoC.selector,  // mintIoC selector: 0xcecac20b
                iocHash, // ioc hash: any 32 bytes
                bytes(iocData), // extraData is ioc data: any bytes
                shareholderSignature // signature: 65 bytes
            ),
            "ReputationRouter: mintIoC invalid signature"
        );
        (uint256 positionMinReportsRequired, uint256 positionReportsReceived) = reputationLock.getLockPositionAmountReports(iocHash);
        require(positionMinReportsRequired <= positionReportsReceived, "ReputationRouter: not enogh reports");
        iocStorage.mintIoC(iocHash, msg.sender, iocData);
        ioc.mint(iocHash, msg.sender);
    }

    /***** VERIFY SIGNATURE FUNCTIONS *****/

    /**
     * @dev verification of sign
     * @param endpoint address of endpoint (20 bytes)
     * @param selector function selector to be signed to call (4 bytes)
     * @param iocHash hash of ioc in database (32 bytes)
     * @param extraData any additional data (>= 0 bytes)
     * @param signature sign of shareholder (65 bytes)
     */
    function verify(address endpoint, bytes4 selector, bytes32 iocHash, bytes memory extraData, bytes memory signature) public view returns (bool) {
        bytes32 endpointHash = getMessageHash(endpoint, selector, iocHash, extraData);
        bytes32 ethSignedEndpointHash = getEthSignedMessageHash(endpointHash);
        address signer = recoverSigner(ethSignedEndpointHash, signature);
        return signer == shareholder ? true : false;
    }

    function getMessageHash(address endpoint, bytes4 selector, bytes32 iocHash, bytes memory extraData) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(endpoint, selector, iocHash, extraData));
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32){
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev return length of array `distribution`
     */
    function getDistributionLength() public view returns (uint256) {
        return distribution.length;
    }

    function getDistributionArray() public view returns (uint256[] memory) {
        return distribution;
    }
    
    /**
     * @dev return numerator and deniminator of distribution.
     */
    function getDistribution(uint256 order) public view returns (uint256 numerator, uint256 denominator) {
        uint256 distributionLength = getDistributionLength();
        if (order < distributionLength) {
            return (distribution[order], distributionSum);
        } else {
            return (0, distributionSum);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/ERC721.sol";
import "./ReputationRouter.sol";

/**
 * @dev Indicator of Comprometations collection
 */
contract IoC is ERC721 {

    ReputationRouter public reputationRouter;

    /**
     * @dev tokenId => iocHash
     */
    mapping(uint256 => bytes32) public iocHash;
 
    modifier onlyReputationRouter() {
        require(msg.sender == address(reputationRouter), "IoC: msg.sender is not reputationRouter");
        _;
    }

    function initialize(address reputationRouter_) public {
        require(address(reputationRouter) == address(0), "IoC: initialized");
        reputationRouter = ReputationRouter(reputationRouter_);
        require(msg.sender == reputationRouter.shareholder() || msg.sender == reputationRouter_, "IoC: invalid reputation router address");
    }

    function mint(bytes32 iocHash_, address to) public onlyReputationRouter {
        uint256 tokenId = totalSupply();
        iocHash[tokenId] = iocHash_;
        _mint(to, tokenId);
    }

    function getIoCStorage() public view returns(address) {
        return address(reputationRouter.iocStorage());
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/ERC20.sol";
import "./ReputationRouter.sol";

contract ReputationToken is ERC20 {

    ReputationRouter public reputationRouter;

    uint256 public totalSupplyCap;

    modifier onlyReputationRouter() {
        require(msg.sender == address(reputationRouter), "Reputation: msg.sender is not reputationRouter");
        _;
    }

    function initialize(address reputationRouter_, uint256 totalSupplyCap_) public {
        __ERC20_init("Reputation Token", "REPT", 18);
        require(address(reputationRouter) == address(0), "ReputationToken: initialized");
        reputationRouter = ReputationRouter(reputationRouter_);
        require(msg.sender == reputationRouter.shareholder() || msg.sender == reputationRouter_, "ReputationToken: invalid reputation router address");
        require(totalSupplyCap_ > 0, "ReputationToken: total supply cap is zero");
        totalSupplyCap = totalSupplyCap_;
    }

    function mint(address account, uint256 amount) public onlyReputationRouter {
        require(totalSupply() + amount <= totalSupplyCap, "ReputationToken: total supply will exceed total supply cap");
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnAll() public {
        uint256 amount = balanceOf(msg.sender);
        _burn(msg.sender, amount);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ReputationRouter.sol";
import "./ReputationToken.sol";

contract ReputationLock {
    
    /**
     * @dev address of reputation router
     */
    ReputationRouter public reputationRouter;

    /**
     * @dev return the total reputation token released
     */
    uint256 public totalReputationReleased;

    /**
     * @dev iocHash => LockPosition
     */
    mapping(bytes32 => ReputationLockPosition) public reputationLockPosition;

    struct ReputationLockPosition {
        uint256 minReportsRequired;         // [minReportsRequired] = amount reports
        uint256 minReputationPerIoC;        // [minReputationForIoC] = REPT
        uint256 reputationForIoC;           // [reputationForIoC] = REPT
        uint256 reportsReceived;            // [reportsReceived] = amount reports
        uint256 reputationReleasedForIoC;   // [reputationReleasedForIoC] = REPT
        address[] endpoints;                // array of endpoints that reported the IoC
        mapping(address => uint256) endpointId; // id of endpoint in array `endpoints`
        mapping(address => uint256) reputationReleased; // reputation released by endpoint
    }

    modifier onlyShareholder() {
        require(msg.sender == reputationRouter.shareholder(), "ReputationLock: msg.sender is not shareholder");
        _;
    }

    modifier onlyReputationRouter() {
        require(msg.sender == address(reputationRouter), "ReputationLock: msg.sender is not reputation router");
        _;
    }

    event AddIoC(address indexed endpointCreator, bytes32 indexed iocHash, uint256 minReportsRequired, uint256 minReputationForIoC, uint256 reputationForIoC);
    
    event ReportIoC(address indexed endpointReporter, bytes32 indexed iocHash, uint256 reportsReceived);

    /***** SHAREHOLDER FUNCTIONS *****/

    function initialize(address reputationRouter_) public {
        require(address(reputationRouter) == address(0), "ReputationLock: initialized");
        reputationRouter = ReputationRouter(reputationRouter_);
        require(msg.sender == reputationRouter.shareholder() || msg.sender == reputationRouter_, "ReputationLock: invalid reputation router address");
        totalReputationReleased = 0;
    }

    /***** REPUTATION ROUTER FUNCTIONS *****/

    function addIoC(bytes32 iocHash, address endpointCreator) public onlyReputationRouter {
        ReputationLockPosition storage position = reputationLockPosition[iocHash];
        position.minReportsRequired = reputationRouter.minReportsRequired();
        position.minReputationPerIoC = reputationRouter.minReputationPerIoC();
        position.reputationForIoC = reputationRouter.reputationPerIoC();
        position.endpointId[endpointCreator] = position.reportsReceived;
        position.endpoints.push(endpointCreator);
        position.reportsReceived++;
        emit AddIoC(endpointCreator, iocHash, position.minReportsRequired, position.minReputationPerIoC, position.reputationForIoC);
    }

    function reportIoC(bytes32 iocHash, address endpointReporter) public onlyReputationRouter {
        ReputationLockPosition storage position = reputationLockPosition[iocHash];
        position.endpointId[endpointReporter] = position.reportsReceived;
        position.endpoints.push(endpointReporter);
        position.reportsReceived++;
        emit ReportIoC(endpointReporter, iocHash, position.reportsReceived);
    }

    function release(bytes32 iocHash, address endpoint) public onlyReputationRouter {
        ReputationLockPosition storage position = reputationLockPosition[iocHash];
        require(position.reportsReceived >= position.minReportsRequired, "ReputationLock: not reached minimal reports required");
        require(position.reputationReleased[endpoint] == 0,  "ReputationLock: reward is released by this endpoint");
        uint256 endpointId = position.endpointId[endpoint];
        ReputationToken reputation = ReputationToken(reputationRouter.reputationToken());
        uint256 reputationAmount;
        if (endpointId < reputationRouter.getDistributionLength()) {
            (uint256 distribution, uint256 distributionSum) = reputationRouter.getDistribution(endpointId);
            reputationAmount = distribution * position.reputationForIoC / distributionSum;
        } else {
            reputationAmount = position.minReputationPerIoC;
        }
        reputation.transfer(endpoint, reputationAmount);
        position.reputationReleased[endpoint] += reputationAmount;
        position.reputationReleasedForIoC += reputationAmount;
        totalReputationReleased += reputationAmount;
    }

    /***** VIEW FUNCTIONS *****/

    // function getLockPosition(bytes32 iocHash) public view returns () {
    //     return reputationLockPosition[iocHash];
    // }

    function getLockPositionAmountReports(bytes32 iocHash) public view returns (uint256 minReportsRequired, uint256 reportsReceived) {
        ReputationLockPosition storage position = reputationLockPosition[iocHash];
        return (position.minReportsRequired, position.reportsReceived);
    }

    function getLockPositionEndpointsLength(bytes32 iocHash) public view returns (uint256) {
        return reputationLockPosition[iocHash].endpoints.length;
    }

    function getLockPositionEndpoint(bytes32 iocHash, uint256 endpointId) public view returns (address) {
        require(endpointId < getLockPositionEndpointsLength(iocHash), "ReputationLock: endpointId >= endpoints length");
        return reputationLockPosition[iocHash].endpoints[endpointId];
    }

    function getLockPositionEndpointId(bytes32 iocHash, address endpoint) public view returns (uint256) {
        ReputationLockPosition storage position = reputationLockPosition[iocHash];
        uint256 endpointId = reputationLockPosition[iocHash].endpointId[endpoint];
        require(position.endpoints[endpointId] == endpoint, "ReputationLock: not existing endpoint for iocHash");
        return endpointId;
    }

    function getLockPositionReleased(bytes32 iocHash, address endpoint) public view returns (uint256) {

    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IReputationRouter {


    function addIoC(bytes32 iocHash, bytes memory shareholderSignature) external;

    function reportIoC(bytes32 iocHash, bytes32 reportHash, bytes memory shareholderSignature) external;

    function release(bytes32 iocHash) external;

    function mintIoC(bytes32 iocHash, string memory iocData, bytes memory shareholderSignature) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension and the Enumerable extention
 */
contract ERC721 {
    //using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /** 
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }


    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.totalSupply(), "ERC721: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }


    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of ERC20 standart.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint8 private _decimals;

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

    /**
     * @dev Sets the values for {name}, {symbol} and {decimals}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_, uint8 decimals_) internal {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the sender of message.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Returns the data of message.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

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
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

     /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
   
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}