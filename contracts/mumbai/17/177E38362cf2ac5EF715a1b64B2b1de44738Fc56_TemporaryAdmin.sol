// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IMetacareNFT.sol";

error TemporaryAdmin__ContractExpired();
error TemporaryAdmin__AddressAlreadyMinted();
error TemporaryAdmin__NotAManager();
error TemporaryAdmin__RequestedMintQuantityExceedsMaxTokensToMint();

contract TemporaryAdmin {
    IMetacareNFT private immutable metacareNFT;
    uint256 public expiresAt;
    address public manager;
    uint256 public maxTokensToMint;
    bool private contractValid;

    mapping(address => bool) private mintedRecipients;
    uint256 public mintedTokens;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    modifier onlyManager() {
        require(msg.sender == manager, "Caller must be owner/manager");
        _;
    }

    modifier onlyValidContract() {
        require(contractValid, "Contract is not valid or already expired");
        _;
    }

    constructor(
        uint256 _expiresAt,
        address _manager,
        address _targetContract,
        uint256 _maxTokensToMint
    ) {
        expiresAt = _expiresAt;
        manager = _manager;
        maxTokensToMint = _maxTokensToMint;
        metacareNFT = IMetacareNFT(_targetContract);

        contractValid = true;
    }

    function mint(address _receiver) public onlyValidContract onlyManager {
        require(block.timestamp <= expiresAt, "Contract already expired");

        require(!isRecipientMinted(_receiver), "Address already minted");

        require(
            (mintedTokens + 1) <= maxTokensToMint,
            "Requested mint quantity exceeds maxTokensToMint"
        );

        metacareNFT.batchMint(_receiver, 1);

        mintedRecipients[_receiver] = true;

        // Emit what token(s) were minted
        uint256 nftSupply = metacareNFT.totalSupply() + 1;
        for (uint256 i = 0; i < 1; i++) {
            emit Transfer(address(this), _receiver, nftSupply - i);
        }

        mintedTokens += 1;
    }

    function closeTemporaryAdminAccount() public {
        contractValid = false;
    }

    function isRecipientMinted(address _receiver) public view returns (bool) {
        return mintedRecipients[_receiver];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMetacareNFT {
    function batchMint(address _receiver, uint256 _quantity) external;

    function totalSupply() external view returns (uint256);
}