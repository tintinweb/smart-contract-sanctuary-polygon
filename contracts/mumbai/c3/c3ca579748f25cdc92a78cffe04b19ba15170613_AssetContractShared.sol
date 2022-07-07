// SPDX-License-Identifier: MIT

import "./AssetContract.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./TokenIdentifiers.sol";


pragma solidity 0.8.4;

contract AssetContractShared is AssetContract, ReentrancyGuard {
    AssetContractShared public migrationTarget;

    mapping(address => bool) public sharedProxyAddresses;

    struct Ownership {
        uint256 id;
        address owner;
    }

    struct NFTVoucher {
        uint256 tokenId;
        string uri;
        address erc20Token;
        uint256 erc20TokenAmount;
        address receiver;
    }

    bytes32 private constant NFT_VOUCHER_TYPEHASH =
    keccak256(
        bytes(
            "NFTVoucher(uint256 tokenId,string uri,address erc20Token,uint256 erc20TokenAmount,address receiver)"
        )
    );

    using TokenIdentifiers for uint256;

    event CreatorChanged(uint256 indexed _id, address indexed _creator);

    mapping(uint256 => address) internal _creatorOverride;

    modifier creatorOnly(uint256 _id) {
        require(
            _isCreatorOrManager(_id, _msgSender()),
            "AssetContractShared#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    modifier isCreatorOrMinter(uint256 _id) {
        require(
            _isCreatorOrMinter(_id, _msgSender()),
            "AssetContractShared#isCreatorOrMinter: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    modifier onlyFullTokenOwner(uint256 _id) {
        require(
            _ownsTokenAmount(_msgSender(), _id, _id.tokenMaxSupply()),
            "AssetContractShared#onlyFullTokenOwner: ONLY_FULL_TOKEN_OWNER_ALLOWED"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI,
        address _migrationAddress
    ) AssetContract(_name, _symbol, _proxyRegistryAddress, _templateURI) {
        migrationTarget = AssetContractShared(_migrationAddress);
    }

    function setProxyRegistryAddress(address _address) public onlyOwnerOrProxy {
        proxyRegistryAddress = _address;
    }

    function addSharedProxyAddress(address _address) public onlyOwnerOrProxy {
        sharedProxyAddresses[_address] = true;
    }

    function removeSharedProxyAddress(address _address)
        public
        onlyOwnerOrProxy
    {
        delete sharedProxyAddresses[_address];
    }

    function disableMigrate() public onlyOwnerOrManager {
        migrationTarget = AssetContractShared(address(0));
    }

    function migrate(Ownership[] memory _ownerships) public onlyOwnerOrManager {
        AssetContractShared _migrationTarget = migrationTarget;
        require(
            _migrationTarget != AssetContractShared(address(0)),
            "AssetContractShared#migrate: MIGRATE_DISABLED"
        );

        string memory _migrationTargetTemplateURI =
            _migrationTarget.templateURI();

        for (uint256 i = 0; i < _ownerships.length; ++i) {
            uint256 id = _ownerships[i].id;
            address owner = _ownerships[i].owner;

            require(
                owner != address(0),
                "AssetContractShared#migrate: ZERO_ADDRESS_NOT_ALLOWED"
            );

            uint256 previousAmount = _migrationTarget.balanceOf(owner, id);

            if (previousAmount == 0) {
                continue;
            }

            _mint(owner, id, previousAmount, "");

            if (
                keccak256(bytes(_migrationTarget.uri(id))) !=
                keccak256(bytes(_migrationTargetTemplateURI))
            ) {
                _setPermanentURI(id, _migrationTarget.uri(id));
            }
        }
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public override nonReentrant isCreatorOrMinter(_id) {
        _mint(_to, _id, _quantity, _data);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public override nonReentrant {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _isCreatorOrMinter(_ids[i], _msgSender()),
                "AssetContractShared#_batchMint: ONLY_CREATOR_ALLOWED"
            );
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    function setURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setURI(_id, _uri);
    }

    function setPermanentURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setPermanentURI(_id, _uri);
    }

    function setCreator(uint256 _id, address _to) public creatorOnly(_id) {
        require(
            _to != address(0),
            "AssetContractShared#setCreator: INVALID_ADDRESS."
        );
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    function creator(uint256 _id) public view returns (address) {
        if (_creatorOverride[_id] != address(0)) {
            return _creatorOverride[_id];
        } else {
            return _id.tokenCreator();
        }
    }

    function maxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    function _origin(uint256 _id) internal pure override returns (address) {
        return _id.tokenCreator();
    }

    function _remainingSupply(uint256 _id)
        internal
        view
        override
        returns (uint256)
    {
        return maxSupply(_id) - totalSupply(_id);
    }

    function _isCreatorOrProxy(uint256 _id, address _address)
        internal
        view
        override
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    function _isCreatorOrManager(uint256 _id, address _address)
        internal
        view
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || managerAddresses[_address];
    }

    function _isCreatorOrMinter(uint256 _id, address _address)
        internal
        view
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || minterAddresses[_address];
    }

    function _isProxyForUser(address _user, address _address)
        internal
        view
        override
        returns (bool)
    {
        if (sharedProxyAddresses[_address]) {
            return true;
        }
        return super._isProxyForUser(_user, _address);
    }

    function redeem(
        address minter,
        NFTVoucher calldata voucher,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV) public payable returns (uint256) {

        require(
            verifyRedeem(minter, voucher, sigR, sigS, sigV),
            "AssetContractShared#redeem: INVALID_SIGNATURE"
        );

        // make sure that the signer is authorized to mint NFTs
        require(
            _isCreatorOrMinter(voucher.tokenId, minter),
            "AssetContractShared#redeem: ONLY_CREATOR_ALLOWED"
        );

        require(!exists(voucher.tokenId), "AssetContractShared#redeem: TOKEN_REDEEMED");

        uint256 tokenBalance = ERC20(voucher.erc20Token).balanceOf(msg.sender);
        require(tokenBalance >= voucher.erc20TokenAmount, "AssetContractShared#redeem: INSUFFICIENT_FUNDS");

        uint256 allowance = ERC20(voucher.erc20Token).allowance(msg.sender, address(this));
        require(allowance >= voucher.erc20TokenAmount, "AssetContractShared#redeem: INSUFFICIENT_ALLOWANCE");

        (bool success, bytes memory result) = payable(address(voucher.erc20Token)).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, voucher.receiver, voucher.erc20TokenAmount));
        if (!success) {
        if (result.length > 0) {
            assembly {
            let result_size := mload(result)
            revert(add(32, result), result_size)
            }
        } else {
            revert("ERC20: TRANSFER_FAILED");
        }
        }

        _mint(msg.sender, voucher.tokenId, 1, bytes(voucher.uri));

        return voucher.tokenId;
    }

    function verifyRedeem(
        address signer,
        NFTVoucher calldata voucher,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "AssetContractShared#verifyRedeem: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashNFTVoucher(voucher)),
                sigV,
                sigR,
                sigS
            );
    }
    
    function hashNFTVoucher(NFTVoucher calldata voucher)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    NFT_VOUCHER_TYPEHASH,
                    voucher.tokenId,
                    keccak256(bytes(voucher.uri)),
                    voucher.erc20Token,
                    voucher.erc20TokenAmount,
                    voucher.receiver
                )
            );
    }
    
    function batchRedeem(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        string[] memory _uris,
        bytes memory _data
    ) public nonReentrant {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _isCreatorOrMinter(_ids[i], _msgSender()),
                "AssetContractShared#_batchRedeem: ONLY_CREATOR_ALLOWED"
            );
        }
        _batchRedeem(_to, _ids, _quantities, _uris, _data);
    }

    function _batchRedeem(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        string[] memory _uris,
        bytes memory _data
    ) internal virtual {
        super._batchMint(_to, _ids, _quantities, _data);
        for (uint256 i = 0; i < _ids.length; i++) {
            _setURI(_ids[i], _uris[i]);
        }
    }
}