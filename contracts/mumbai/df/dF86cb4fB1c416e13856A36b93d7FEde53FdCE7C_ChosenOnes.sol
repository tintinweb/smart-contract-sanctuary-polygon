// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC721.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract ChosenOnes is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable
{
    using StringsUpgradeable for uint256;

    struct Voucher {
        bool everybody;
        address minter;
        uint256 drop_id;
        uint256 start_date; // 0 means no limit
        uint256 end_date; // 0 means no limit
        uint256 wallet_limit; // 0 means no limit
        uint256 price;
    }

    // ROLES
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // DATA Setting
    address payable private treasury;
    string private base_uri;
    // DATA Drops
    uint256[] private drop_ids;
    mapping(uint256 => uint256) private index_drop;
    mapping(uint256 => uint256) private drop_max;
    // DATA Tokens
    mapping(uint256 => uint256) private token_drop;
    mapping(uint256 => uint256[]) private drop_tokens;

    function initialize() public initializer {
        __ERC721_init("Chosen Ones", "CO");
        __EIP712_init("Chosen Ones", "1.0.0");
        __Pausable_init();
        __ERC721Enumerable_init();
        __AccessControl_init();

        address owner = address(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(OWNER_ROLE, owner);
        _setupRole(WITHDRAW_ROLE, owner);

        treasury = payable(owner);
        base_uri = "https://nft.chosenones.io/api/";
    }

    // OVERRIDE
    function tokenURI(uint256 token_id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(token_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    getDropOf(token_id).toString(),
                    "/",
                    token_id.toString(),
                    ".json"
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked(base_uri, "/"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            AccessControlUpgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 token_id
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, token_id);
    }

    // Setting
    function GetTreasury() public view returns (address payable) {
        return treasury;
    }

    function SetTreasury(address payable value) public {
        treasury = value;
    }

    function GetBaseURI() public view returns (string memory) {
        return base_uri;
    }

    function SetBaseURI(string memory value) public {
        base_uri = value;
    }

    // Drop
    function setDrop(uint256 drop_id, uint256 max) public onlyRole(OWNER_ROLE) {
        require(max > 0, "Max can not be zero");
        bool IsNew = drop_max[drop_id] == 0;
        if (IsNew) {
            drop_ids.push(drop_id);
            index_drop[drop_id] = drop_ids.length - 1;
            drop_max[drop_id] = max;
        } else {
            drop_max[drop_id] = max;
        }
    }

    function delDrop(uint256 drop_id) public onlyRole(OWNER_ROLE) {
        require(drop_max[drop_id] > 0, "Drop does not exist");
        uint256 index = index_drop[drop_id];
        delete drop_ids[index];
        delete index_drop[drop_id];
        delete drop_max[drop_id];
    }

    function getDropIDs() public view returns (uint256[] memory) {
        return drop_ids;
    }

    function getDropCount() public view returns (uint256) {
        return drop_ids.length;
    }

    function getDropAtIndex(uint256 index) public view returns (uint256) {
        return drop_ids[index];
    }

    function getDropIndex(uint256 drop_id) public view returns (uint256) {
        return index_drop[drop_id];
    }

    function getDropMax(uint256 drop_id) public view returns (uint256) {
        return drop_max[drop_id];
    }

    // Token

    function getDropOf(uint256 token_id) public view returns (uint256) {
        return token_drop[token_id];
    }

    function getDropTokenIDs(uint256 drop_id) public view returns (uint256[] memory) {
        return drop_tokens[drop_id];
    }

    function getDropTokenCount(uint256 drop_id) public view returns (uint256) {
        return drop_tokens[drop_id].length;
    }

    function getDropTokenAtIndex(uint256 drop_id, uint256 index) public view returns (uint256) {
        return drop_tokens[drop_id][index];
    }

    // MINT
    function mint(
        Voucher memory voucher,
        uint256 count,
        bytes memory Signature
    ) public payable whenNotPaused {
        // Inputs
        require(count > 0, "Count can not be less than 1.");
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSAUpgradeable.recover(_hash(voucher), Signature)
            ),
            "Signature is not valid."
        );

        require(
            drop_tokens[voucher.drop_id].length < drop_max[voucher.drop_id],
            "All tokens in the drop have been sold out."
        );
        require(
            drop_tokens[voucher.drop_id].length + count <=
                drop_max[voucher.drop_id],
            "Insufficient count of token requested."
        );

        // Voucher
        require(
            voucher.everybody || voucher.minter == address(voucher.minter),
            "You are not a valid minter."
        );
        require(
            voucher.start_date <= block.timestamp,
            "Drop has not been started yet."
        );
        require(
            voucher.end_date == 0 || voucher.end_date >= block.timestamp,
            "Drop has been finished."
        );
        require(
            voucher.wallet_limit == 0 ||
                balanceOf(msg.sender) + count <= voucher.wallet_limit,
            "drop.wallet_limit is exceeded."
        );
        require(voucher.price * count <= msg.value, "Drop price is not valid");

        // Mint
        for (uint256 index = 0; index < count; index++) {
            uint256 next = totalSupply() + 1;
            drop_tokens[voucher.drop_id].push(next);
            token_drop[next] = voucher.drop_id;
            _safeMint(msg.sender, next);
        }
    }

    function withdraw(uint256 amount)
        public
        onlyRole(WITHDRAW_ROLE)
        whenNotPaused
    {
        treasury.transfer(amount);
    }

    function withdrawAll() public onlyRole(WITHDRAW_ROLE) {
        withdraw(address(this).balance);
    }

    function _hash(Voucher memory voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(bool everybody,address minter,uint256 drop_id,uint256 start_date,uint256 end_date,uint256 wallet_limit,uint256 price)"
                        ),
                        voucher.everybody,
                        voucher.minter,
                        voucher.drop_id,
                        voucher.start_date,
                        voucher.end_date,
                        voucher.wallet_limit,
                        voucher.price
                    )
                )
            );
    }
}