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

    // STRUCT
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
    bytes32 public constant ROLE_OWNER = keccak256("O");
    bytes32 public constant ROLE_SIGNER = keccak256("S");
    bytes32 public constant ROLE_WITHDRAW = keccak256("W");
    // DATA
    address payable public treasury;
    string public baseURI;
    mapping(uint256 => uint256) internal drop_max; // [drop_id => max]
    mapping(uint256 => uint256) internal token_drop; // [drop_id => max]
    mapping(uint256 => uint256[]) internal drop_tokens; // [drop_id => max]

    function initialize() public initializer {
        string memory name = "Chosen Ones";
        string memory symbol = "CO";
        __ERC721_init(name, symbol);
        __EIP712_init(name, symbol);
        __ERC721Enumerable_init();
        __AccessControl_init();

        address owner = address(msg.sender);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_WITHDRAW, owner);
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_WITHDRAW, ROLE_OWNER);

        treasury = payable(owner);
        // baseURI = "https://nft.chosenones.io/api/";
    }

    // SETTING
    function setTreasury(address payable value) public onlyRole(ROLE_OWNER) {
        treasury = value;
    }

    function setBaseURI(string memory value) public onlyRole(ROLE_OWNER) {
        baseURI = value;
    }

    // OVERRIDE
    function tokenURI(uint256 token_id)
        public
        view
        virtual
        override
        returns (string memory)
    {
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
        return string(abi.encodePacked(baseURI, "/"));
    }

    // function getDropMax(uint256 drop_id) public view returns (uint256) {
    //     return drop_max[drop_id];
    // }

    // function getDrop(uint256 drop_id) public view returns (Drop memory) {
    //     requireDropID(drop_id, false);
    //     return drop_max[drop_id];
    // }

    function setDrop(uint256 drop_id, uint256 max) public onlyRole(ROLE_OWNER) {
        drop_max[drop_id] = max;
    }

    function delDrop(uint256 drop_id) public onlyRole(ROLE_OWNER) {
        delete drop_max[drop_id];
    }

    // Token
    // function gettoken_ids() public view returns (uint256[] memory) {
    //     return token_ids;
    // }

    // function getTokenCount() public view returns (uint256) {
    //     return token_ids.length;
    // }

    function getDropOf(uint256 token_id) public view returns (uint256) {
        return drop_max[token_id];
    }

    // function getDroptoken_ids(uint256 drop_id)
    //     public
    //     view
    //     returns (uint256[] memory)
    // {
    //     return drop_tokens[drop_id];
    // }

    // function getDropTokenCount(uint256 drop_id) public view returns (uint256) {
    //     return drop_tokens[drop_id].length;
    // }

    // MINT
    function mint(
        Voucher memory voucher,
        uint256 count,
        bytes memory Signature
    ) public payable whenNotPaused {
        // Inputs
        require(count > 0, "0");
        // require(count > 0, "Count can not be less than 1.");
        require(
            hasRole(
                ROLE_SIGNER,
                ECDSAUpgradeable.recover(_hash(voucher), Signature)
            ),
            "1"
            // "Signature is not valid."
        );

        require(
            drop_tokens[voucher.drop_id].length < drop_max[voucher.drop_id],
            "2"
            // "All tokens in the drop have been sold out."
        );
        require(
            drop_tokens[voucher.drop_id].length + count <=
                drop_max[voucher.drop_id],
            "3"
            // "Insufficient count of token requested."
        );

        // Voucher
        require(
            !voucher.everybody && voucher.minter == address(voucher.minter),
            "4"
            // "You are not a valid minter."
        );
        // requireDropID(, false);
        require(
            voucher.start_date <= block.timestamp,
            "5"
            // "Drop has not been started yet."
        );
        require(
            voucher.end_date == 0 || voucher.end_date >= block.timestamp,
            "6"
            // "Drop has been finished."
        );
        require(
            voucher.wallet_limit != 0 &&
                balanceOf(msg.sender) + count <= voucher.wallet_limit,
            "7"
            // "drop.wallet_limit is exceeded."
        );
        require(
            voucher.price * count <= msg.value,
            "8"
            // "Drop price is not valid"
        );

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
        onlyRole(ROLE_WITHDRAW)
        whenNotPaused
    {
        treasury.transfer(amount);
    }

    // function withdrawAll() public onlyRole(ROLE_WITHDRAW) {
    //     withdraw(address(this).balance);
    // }

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