// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Credentials.sol";
import "./SolutionVerifier.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165Storage.sol";
import "./SafeMath.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";

interface RequiredPass {
    function balanceOf(address _owner) external view returns (uint256);
}

contract TesterCreator is SolutionVerifier, ERC165Storage, IERC721, IERC721Metadata, IERC721Enumerable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Revert messages -- Block Qualified Testers cannot be transferred
    // This is done to aid with credentials: one can verify on-chain the address that created a test,
    // that is, the owner of the corresponding Block Qualified Tester NFT.
    string approveRevertMessage = "BQT: cannot approve testers";
    string transferRevertMessage = "BQT: cannot transfer testers";

    // Smart contract for giving credentials
    Credentials public credentialsContract;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Number of testers that have been created
    uint256 private _nTesters;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    struct OnChainTester {
        uint256 solutionHash;
        uint256 prize;
        uint32 solvers;
        uint32 timeLimit;
        uint32 credentialLimit;
        address requiredPass;
        string credentialsGained;
    }

    // Mapping containing the information about each of the defined testers
    mapping(uint256 => OnChainTester) private _testers;

    // Mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;  // URL containing the multiple choice test for each tester

    // Salts that have been already used before for submitting solutions
    mapping (uint256 => bool) public usedSalts;


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol`
     */
    constructor (address _poseidonHasher) SolutionVerifier(_poseidonHasher) {
        _name = "Block Qualified Testers";
        _symbol = "BQT";

        credentialsContract = new Credentials();

        // register the supported interfaces to conform to ERC721 via ERC165
        /*
        *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
        *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
        *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
        *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
        *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
        *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
        *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
        *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
        *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
        *
        *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
        *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
        */
        _registerInterface(0x80ac58cd);
        /*
        *     bytes4(keccak256('name()')) == 0x06fdde03
        *     bytes4(keccak256('symbol()')) == 0x95d89b41
        *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
        *
        *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
        */
        _registerInterface(0x5b5e139f);
        /*
        *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
        *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
        *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
        *
        *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
        */
        _registerInterface(0x780e9d63);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function createTester(
        string memory _testerURI, 
        uint256 _solutionHash, 
        uint32 _timeLimit,
        uint32 _credentialLimit,
        address _requiredPass,
        string memory _credentialGained
    ) external payable {
        require(_timeLimit > block.timestamp, "Time limit is in the past");
        require(_credentialLimit > 0, "Credential limit must be above zero");
        if(_requiredPass != address(0)) {
            require(RequiredPass(_requiredPass).balanceOf(msg.sender) >= 0);  // dev: invalid required pass address provided
        }

        // Increase the number of testers available
        uint256 _testerId = _nTesters + 1;
        _nTesters++;

        // Setting the given URI that holds all of the questions
        _tokenURIs[_testerId] = _testerURI;

        // Defining the OnChainTester object for this testerId
        _testers[_testerId] = OnChainTester(
            _solutionHash, 
            msg.value,
            0,
            _timeLimit,
            _credentialLimit,
            _requiredPass,
            _credentialGained
        );

        // Minting this new nft
        _holderTokens[msg.sender].add(_testerId);
        _tokenOwners.set(_testerId, msg.sender);
        emit Transfer(address(0), msg.sender, _testerId);
    }
    
    /**
     * @dev Returns the struct that defines a tester
     */
    function getTester(uint256 testerId) external view returns (OnChainTester memory) {
        require(_exists(testerId), "Tester does not exist");
        return _testers[testerId];
    }

    /**
     * @dev Returns if a given tester is still valid, that is, if it exists
     */
    function testerExists(uint256 testerId) external view returns (bool) {
        return _exists(testerId);
    }

    /**
     * @dev Returns the test URI, which contains inside the questions
     */
    function tokenURI(uint256 testerId) external view override returns (string memory) {
        require(_exists(testerId), "Tester does not exist");
        return _tokenURIs[testerId];
    }

    /**
     * @dev Allows the owner of a tester to no longer recognize it as valid by essentially burning it
     * Deleting a test is **final**
     */
    function deleteTester(uint256 testerId) external {
        require(_exists(testerId), "Tester does not exist");
        require(ownerOf(testerId) == msg.sender, "Deleting tester that is not own");

        // Burns the token from the `msg.sender` holdings
        _holderTokens[msg.sender].remove(testerId);
        _tokenOwners.remove(testerId);

        bool wasSolved = _testers[testerId].solvers == 0 ? false : true;
        uint256 prize = _testers[testerId].prize;

        // Deletes the corresponding URI and OnChainTester object
        delete _testers[testerId];
        delete _tokenURIs[testerId];

        // Returns the funds to the owner if the test was never solved
        if (!wasSolved) {
            payable(msg.sender).transfer(prize);
        }

        emit Transfer(msg.sender, address(0), testerId);
    }

    function solveTester(
        uint256 testerId, 
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input  // [solvingHash, salt]
    ) external nonReentrant returns (bool verifiedSolution) {
        require(_exists(testerId), "Solving test that does not exist");
        require(!usedSalts[input[1]], "Salt was already used");

        OnChainTester memory _tester = _testers[testerId];
        require(msg.sender != ownerOf(testerId), "Tester cannot be solved by owner");
        require(_tester.solvers < _tester.credentialLimit, "Maximum number of credentials reached");
        require(block.timestamp <= _tester.timeLimit, "Time limit for this credential reached");
        if(_tester.requiredPass != address(0)) {
            require(RequiredPass(_tester.requiredPass).balanceOf(msg.sender) > 0, "Solver does not own the required token");
        }

        verifiedSolution = verifySolution(a, b, c, input, _tester.solutionHash);

        if (verifiedSolution) {
            if (_tester.solvers == 0) {  // Was the first solver for this multiple choice test
                payable(msg.sender).transfer(_tester.prize);
            }

            credentialsContract.giveCredentials(msg.sender, testerId);

            _testers[testerId].solvers++;
        } 

        usedSalts[input[1]] = true;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256 count) {
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(_owner), "Index out of bounds");
        return _holderTokens[_owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "Index out of bounds");  
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     *
     * Only present to be ERC-721 compliant. Testers cannot be transferred, and as such cannot be approved for spending.
     */
    function approve(address /* _approved */, uint256 /* _tokenId */) public view virtual override {
        revert(approveRevertMessage);
    }

    /**
     * @dev See {IERC721-getApproved}.
     *
     * Only present to be ERC-721 compliant. Testers cannot be transferred, and as such are never approved for spending.
     */
    function getApproved(uint256 /* tokenId */) public view virtual override returns (address) {
        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *
     * Only present to be ERC721 compliant. Testers cannot be transferred, and as such cannot be approved for spending.
     */
    function setApprovalForAll(address /* _operator */, bool /* _approved */) public view virtual override {
        revert(approveRevertMessage);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     *
     * Only present to be ERC-721 compliant. Testers cannot be transferred, and as such are never approved for spending.
     */
    function isApprovedForAll(address /* owner */, address /* operator */) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *
     * Only present to be ERC721 compliant. Testers cannot be transferred.
     */
    function transferFrom(address /* from */, address /* to */, uint256 /* tokenId */) public view virtual override {
        revert(transferRevertMessage);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *
     * Only present to be ERC721 compliant. Testers cannot be transferred.
     */
    function safeTransferFrom(address /* from */, address /* to */, uint256 /* tokenId */, bytes memory /* _data */) public view virtual override {
        revert(transferRevertMessage);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

}