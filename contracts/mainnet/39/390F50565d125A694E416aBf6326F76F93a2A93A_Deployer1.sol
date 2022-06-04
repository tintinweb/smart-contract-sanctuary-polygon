// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {WhitelistPredeterminedNFTSaleManager} from "../sale/WhitelistPredeterminedNFTSaleManager.sol";
import {MojoSeedERC721} from "../token/erc721/MojoSeedERC721.sol";
import {MojoERC721} from "../token/erc721/MojoERC721.sol";
import {Sprouter, IMojo, IMojoSeed} from "../sprouting/Sprouter.sol";
import {BasicTimelockController} from "../governance/BasicTimelockController.sol";

library TimelockControllerDeployer {
    function deploy(address owner, uint256 minDelay)
        public
        returns (address payable)
    {
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = owner;
        executors[0] = owner;
        return
            payable(
                address(
                    new BasicTimelockController(minDelay, proposers, executors)
                )
            );
    }
}

library SaleManagerDeployer {
    function deploy(address owner) public returns (address) {
        return address(new WhitelistPredeterminedNFTSaleManager(owner));
    }
}

library MojoSeedDeployer {
    function deploy(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) public returns (address) {
        return address(new MojoSeedERC721(owner, name, symbol, baseURI));
    }
}

library MojoDeployer {
    function deploy(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) public returns (address) {
        return address(new MojoERC721(owner, name, symbol, baseURI));
    }
}

library SprouterDeployer {
    function deploy(
        address owner,
        address mojoContract,
        address mojoSeedContract,
        uint256 sproutingDelay
    ) public returns (address) {
        return
            address(
                new Sprouter(
                    owner,
                    IMojo(mojoContract),
                    IMojoSeed(mojoSeedContract),
                    sproutingDelay
                )
            );
    }
}

library ERC721Helpers {
    struct ERC721Args {
        string name;
        string symbol;
        string baseURI;
        address payable royaltyRecipientAddress;
        uint96 royaltyPercentageBasisPoints;
    }
}

contract Deployer1 {
    event Deployment(string contractName, address contractAddress);

    constructor(
        address owner,
        uint256 minTimelockDelay,
        ERC721Helpers.ERC721Args memory mojoSeedArgs,
        ERC721Helpers.ERC721Args memory mojoArgs,
        uint256 sproutingDelay
    ) {
        deploy(owner, minTimelockDelay, mojoSeedArgs, mojoArgs, sproutingDelay);
    }

    function deploy(
        address owner,
        uint256 minTimelockDelay,
        ERC721Helpers.ERC721Args memory mojoSeedArgs,
        ERC721Helpers.ERC721Args memory mojoArgs,
        uint256 sproutingDelay
    ) private {
        address payable timelockController = TimelockControllerDeployer.deploy(
            owner,
            minTimelockDelay
        );
        emit Deployment("BasicTimelockController", timelockController);

        address saleManager = SaleManagerDeployer.deploy(owner);
        emit Deployment("WhitelistPredeterminedNFTSaleManager", saleManager);

        address mojoSeed = MojoSeedDeployer.deploy(
            address(this),
            mojoSeedArgs.name,
            mojoSeedArgs.symbol,
            mojoSeedArgs.baseURI
        );
        emit Deployment("MojoSeedERC721", mojoSeed);

        address mojo = MojoDeployer.deploy(
            address(this),
            mojoArgs.name,
            mojoArgs.symbol,
            mojoArgs.baseURI
        );
        emit Deployment("MojoERC721", mojo);

        address sprouter = SprouterDeployer.deploy(
            address(this),
            mojo,
            mojoSeed,
            0
        );
        emit Deployment("Sprouter", sprouter);

        MojoSeedERC721(mojoSeed).setRoyaltiesForAll(
            mojoSeedArgs.royaltyRecipientAddress,
            mojoSeedArgs.royaltyPercentageBasisPoints
        );
        MojoERC721(mojo).setRoyaltiesForAll(
            mojoArgs.royaltyRecipientAddress,
            mojoArgs.royaltyPercentageBasisPoints
        );
        MojoERC721(mojo).setMinter(sprouter, true);

        MojoSeedERC721(mojoSeed).setMinter(saleManager, true);

        MojoSeedERC721(mojoSeed).setMinter(address(this), true);
        MojoSeedERC721(mojoSeed).mintTo(address(this));
        MojoSeedERC721(mojoSeed).setMinter(address(this), false);

        Sprouter(sprouter).setPlantingActive(true);
        MojoSeedERC721(mojoSeed).approveAndCall(sprouter, 1);
        Sprouter(sprouter).sprout(1, owner);
        Sprouter(sprouter).setSproutingDelay(sproutingDelay);
        Sprouter(sprouter).setPlantingActive(false);

        MojoSeedERC721(mojoSeed).transferOwnership(owner);
        MojoERC721(mojo).transferOwnership(owner);
        Sprouter(sprouter).transferOwnership(owner);

        //Verify ownership of all 5 deployed contracts
        assert(
            BasicTimelockController(timelockController).getMinDelay() ==
                minTimelockDelay
        );
        assert(
            WhitelistPredeterminedNFTSaleManager(saleManager).owner() == owner
        );
        assert(MojoSeedERC721(mojoSeed).owner() == owner);
        assert(MojoERC721(mojo).owner() == owner);
        assert(Sprouter(sprouter).owner() == owner);

        //The first Moj-Seed was minted and burned
        assert(MojoSeedERC721(mojoSeed).isMinter(address(this)) == false);
        assert(MojoSeedERC721(mojoSeed).isMinter(owner) == false);
        assert(MojoSeedERC721(mojoSeed).isMinter(saleManager) == true);
        assert(MojoSeedERC721(mojoSeed).balanceOf(owner) == 0);
        assert(MojoSeedERC721(mojoSeed).totalSupply() == 0);
        assert(equals(MojoSeedERC721(mojoSeed).name(), mojoSeedArgs.name));
        assert(equals(MojoSeedERC721(mojoSeed).symbol(), mojoSeedArgs.symbol));
        assert(
            equals(
                MojoSeedERC721(mojoSeed).baseTokenURI(),
                mojoSeedArgs.baseURI
            )
        );
        assert(
            MojoSeedERC721(mojoSeed).royaltyRecipient() ==
                mojoSeedArgs.royaltyRecipientAddress
        );
        assert(
            MojoSeedERC721(mojoSeed).royaltyPercentageBasisPoints() ==
                mojoSeedArgs.royaltyPercentageBasisPoints
        );

        //Sprouter minted the first Mojo to the owner
        assert(MojoERC721(mojo).isMinter(address(this)) == false);
        assert(MojoERC721(mojo).isMinter(owner) == false);
        assert(MojoERC721(mojo).isMinter(sprouter) == true);
        assert(MojoERC721(mojo).balanceOf(owner) == 1);
        assert(MojoERC721(mojo).ownerOf(1) == owner);
        assert(MojoERC721(mojo).totalSupply() == 1);
        assert(equals(MojoERC721(mojo).name(), mojoArgs.name));
        assert(equals(MojoERC721(mojo).symbol(), mojoArgs.symbol));
        assert(equals(MojoERC721(mojo).baseTokenURI(), mojoArgs.baseURI));
        assert(
            MojoERC721(mojo).royaltyRecipient() ==
                mojoArgs.royaltyRecipientAddress
        );
        assert(
            MojoERC721(mojo).royaltyPercentageBasisPoints() ==
                mojoArgs.royaltyPercentageBasisPoints
        );

        assert(Sprouter(sprouter).sproutingDelay() == sproutingDelay);
        assert(Sprouter(sprouter).isSeedPlanted(1) == false);
        assert(Sprouter(sprouter).plantingActive() == false);
        assert(address(Sprouter(sprouter).mojoSeedContract()) == mojoSeed);
        assert(address(Sprouter(sprouter).mojoContract()) == mojo);
    }

    function equals(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/MerkleProof.sol";
import "./OwnerWithdrawable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INFTWithMintById {
    function mintTo(address to) external returns (uint256);
}

error InvalidProof();
error SaleIsNotActive();
error InvalidEtherAmount();
error TokenBalanceToLow();
error NotEnoughTokensAllowed();
error UnsupportedERC20TokenUsedAsPayment();
error PrepaidSaleCannotHavePaymentOptions();
error CannotPayForPrepaidSale();
error CannotClaimAboveMaxAllocation();
error CannotClaimAboveMaxSupplyForSale();

/**
 * @title WhitelistPredeterminedNFTSaleManager
 * @notice Contract for a selling and minting NFTs
 */
contract WhitelistPredeterminedNFTSaleManager is
    OwnerWithdrawable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    event SaleCreate(
        uint256 indexed saleId,
        address nftContract,
        address treasuryAddress,
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 maxAllocationPerAccount,
        uint256 ethPrice,
        address[] erc20Addresses,
        uint256[] erc20Prices,
        bool prepaid
    );
    event SaleEnd(uint256 indexed saleId);
    event SaleSoldOut(uint256 indexed saleId);
    event NFTClaim(
        uint256 indexed saleId,
        address indexed account,
        uint256 tokenId,
        address erc20Address
    );

    struct Sale {
        mapping(address => uint256) erc20Prices;
        mapping(address => uint256[]) claimedTokens;
        bytes32 merkleRoot;
        uint256 maxSupply;
        uint256 totalMintedCount;
        uint256 maxAllocationPerAccount;
        uint256 ethPrice;
        //The NFT contract that will be used for minting
        INFTWithMintById nftContract;
        address treasuryAddress;
        bool active;
        bool prepaid;
    }

    mapping(uint256 => Sale) public sales;
    uint256 public saleCount;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function createSale(
        INFTWithMintById nftContract,
        address treasuryAddress,
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 maxAllocationPerAccount,
        uint256 ethPrice,
        address[] memory erc20Addresses,
        uint256[] memory erc20Prices,
        bool prepaid
    ) public onlyOwner {
        saleCount++;

        sales[saleCount].active = true;
        sales[saleCount].merkleRoot = merkleRoot;
        sales[saleCount].maxSupply = maxSupply;
        sales[saleCount].maxAllocationPerAccount = maxAllocationPerAccount;
        sales[saleCount].nftContract = nftContract;
        sales[saleCount].treasuryAddress = treasuryAddress;
        sales[saleCount].prepaid = prepaid;

        if (prepaid) {
            if (ethPrice != 0) {
                revert PrepaidSaleCannotHavePaymentOptions();
            }

            if (erc20Addresses.length != 0 || erc20Prices.length != 0) {
                revert PrepaidSaleCannotHavePaymentOptions();
            }
        } else {
            sales[saleCount].ethPrice = ethPrice;

            for (uint256 i = 0; i < erc20Addresses.length; i++) {
                sales[saleCount].erc20Prices[erc20Addresses[i]] = erc20Prices[
                    i
                ];
            }
        }

        emit SaleCreate(
            saleCount,
            address(nftContract),
            treasuryAddress,
            merkleRoot,
            maxSupply,
            maxAllocationPerAccount,
            ethPrice,
            erc20Addresses,
            erc20Prices,
            prepaid
        );
    }

    function endSale(uint256 saleId) public onlyOwner {
        sales[saleId].active = false;
        emit SaleEnd(saleId);
    }

    function erc20PricesForSale(uint256 saleId, address[] memory erc20Addresses)
        public
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](erc20Addresses.length);

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            prices[i] = sales[saleId].erc20Prices[erc20Addresses[i]];
        }

        return prices;
    }

    function buy(
        uint256 saleId,
        bytes32[] memory merkleProof,
        address erc20Address
    ) public payable nonReentrant {
        _buy(saleId, 1, merkleProof, erc20Address);
    }

    function buyMultiple(
        uint256 saleId,
        uint256 tokenCount,
        bytes32[] memory merkleProof,
        address erc20Address
    ) public payable nonReentrant {
        _buy(saleId, tokenCount, merkleProof, erc20Address);
    }

    function claimedTokens(uint256 saleId, address account)
        public
        view
        returns (uint256[] memory)
    {
        Sale storage sale = sales[saleId];

        return sale.claimedTokens[account];
    }

    function _buy(
        uint256 saleId,
        uint256 tokenCount,
        bytes32[] memory merkleProof,
        address erc20Address
    ) private {
        address msgSender = _msgSender();

        Sale storage sale = sales[saleId];

        if (!sale.active) {
            revert SaleIsNotActive();
        }

        //Users have a maximum amount of tokens they can mint per sale
        //If maxAllocationPerAccount is 0 then there is no limit
        if (
            sale.maxAllocationPerAccount != 0 &&
            sale.claimedTokens[msgSender].length + tokenCount >
            sale.maxAllocationPerAccount
        ) {
            revert CannotClaimAboveMaxAllocation();
        }

        manageSaleTokenIssuence(saleId, sale, tokenCount);

        //If the sale does not have a merkle root, then it does not have a whitelist and no verification is needed
        if (sale.merkleRoot != 0x0) {
            verify(sale.merkleRoot, merkleProof, msgSender);
        }

        if (erc20Address == address(0)) {
            payWithETH(sale, tokenCount);
        } else {
            payWithERC20(erc20Address, sale, tokenCount);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = mint(sale);
            emit NFTClaim(saleId, msgSender, tokenId, erc20Address);
        }
    }

    function mint(Sale storage sale) private returns (uint256) {
        address msgSender = _msgSender();

        uint256 tokenId = sale.nftContract.mintTo(msgSender);

        sale.claimedTokens[msgSender].push(tokenId);

        return tokenId;
    }

    function payWithETH(Sale storage sale, uint256 tokenCount) private {
        if (sale.prepaid) {
            if (msg.value != 0) {
                revert CannotPayForPrepaidSale();
            }

            return;
        }

        uint256 amount = sale.ethPrice * tokenCount;
        address paymentRecipient = sale.treasuryAddress;

        //If the treasury address is not specified, the payment is done to the contract itself
        if (paymentRecipient == address(0)) {
            paymentRecipient = address(this);
        }

        if (msg.value != amount) {
            revert InvalidEtherAmount();
        } else {
            //If the recipient is not the contract itself, then redirect the ETH to the recipient
            //Otherwise, it is kept with the contract
            if (paymentRecipient != address(this)) {
                (bool sent, ) = paymentRecipient.call{value: amount}("");

                if (!sent) {
                    revert FailedToSendEther();
                }
            }
        }
    }

    function payWithERC20(
        address erc20Address,
        Sale storage sale,
        uint256 tokenCount
    ) private {
        address msgSender = _msgSender();

        if (sale.prepaid) {
            if (erc20Address != address(0)) {
                revert CannotPayForPrepaidSale();
            }

            return;
        }

        address paymentRecipient = sale.treasuryAddress;

        //If the treasury address is not specified, the payment is done to the contract itself
        if (paymentRecipient == address(0)) {
            paymentRecipient = address(this);
        }

        //Check if the ERC20 token is allowed as payment
        if (sale.erc20Prices[erc20Address] == 0) {
            revert UnsupportedERC20TokenUsedAsPayment();
        }

        //Get the price of the NFT in the ERC20 token
        uint256 price = sale.erc20Prices[erc20Address];
        uint256 amount = price * tokenCount;

        //Get the ERC20 token used for payment
        IERC20 token = IERC20(erc20Address);

        //Check if the buyer has enough tokens
        uint256 tokenBalance = token.balanceOf(address(msgSender));
        if (tokenBalance < amount) {
            revert TokenBalanceToLow();
        }

        //Get the amount of tokens allowed to be spent
        uint256 allowance = token.allowance(msgSender, address(this));

        //Check if the buyer allowed enough tokens to be used for the payment
        if (allowance < amount) {
            revert NotEnoughTokensAllowed();
        }

        token.safeTransferFrom(msgSender, paymentRecipient, amount);
    }

    function verify(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        address account
    ) private pure {
        bytes32 node = keccak256(abi.encodePacked(account));

        bool isValid = MerkleProof.verify(merkleProof, merkleRoot, node);

        if (!isValid) {
            revert InvalidProof();
        }
    }

    /**
     * @dev Limits selling tokens to a certain amount (maxSupply)
     * If limit is reached then the sale ends (sale is no longer active)
     */
    function manageSaleTokenIssuence(
        uint256 saleId,
        Sale storage sale,
        uint256 tokenCount
    ) private {
        sale.totalMintedCount += tokenCount;

        if (sale.totalMintedCount > sale.maxSupply) {
            revert CannotClaimAboveMaxSupplyForSale();
        } else if (sale.totalMintedCount == sale.maxSupply) {
            sale.active = false;
            emit SaleSoldOut(saleId);
            emit SaleEnd(saleId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./base/PlanetMojoERC721Base.sol";

/**
 * @title MojoSeedERC721
 * @dev Contract for the Mojo Seed non-fungible token
 */
contract MojoSeedERC721 is PlanetMojoERC721Base {
    constructor(
        address _owner, 
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    )
        PlanetMojoERC721Base(_owner, _name, _symbol, _baseUri) {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./base/PlanetMojoERC721Base.sol";

/**
 * @title MojoERC721
 * @dev Contract for the Mojo non-fungible token
 */
contract MojoERC721 is PlanetMojoERC721Base {
    constructor(
        address _owner, 
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    )
        PlanetMojoERC721Base(_owner, _name, _symbol, _baseUri) {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../token/erc721/payable/IERC721PayableSpender.sol";

interface IMojo is IERC721 {
    function exists(uint256 tokenId) external returns (bool);

    function mintById(address to, uint256 tokenId) external;
}

interface IMojoSeed is IERC721 {
    function burn(uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/**
 * @title Sprouter
 * @notice Contract for sprouting Mojo Seeds into Mojos
 */
contract Sprouter is Ownable, IERC721PayableSpender, IERC165 {
    event MojoSeedPlanted(uint256 indexed seedId, address indexed owner);
    event MojoSprout(
        uint256 indexed seedId,
        address indexed owner,
        address indexed recipient
    );
    event PlantingActiveChange(bool plantingActive);
    event MojoSeedContractAddressChange(
        address oldMojoSeedContract,
        address newMojoSeedContract
    );
    event MojoContractAddressChange(
        address oldMojoContract,
        address newMojoContract
    );
    event SproutingDelayChange(uint256 oldDelay, uint256 newDelay);

    struct SeedStorage {
        // Mapping from owner to list of owned token IDs
        mapping(address => uint256[]) ownedTokens;
        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) allTokensIndex;
        // Mapping from token id to block number at time of planting
        mapping(uint256 => uint256) seedPlantBlockstamp;
    }

    //The ERC-165 identifier for the ERC-173 Ownable standard is 0x7f5828d0
    bytes4 private constant INTERFACE_ID_ERC173 = 0x7f5828d0;

    bool public plantingActive;
    IMojo public mojoContract;
    IMojoSeed public mojoSeedContract;
    uint256 public sproutingDelay;

    SeedStorage private seeds;

    constructor(
        address _owner,
        IMojo _mojoContract,
        IMojoSeed _mojoSeedContract,
        uint256 _sproutingDelay
    ) {
        _transferOwnership(_owner);
        mojoContract = _mojoContract;
        mojoSeedContract = _mojoSeedContract;
        sproutingDelay = _sproutingDelay;
    }

    function setPlantingActive(bool active) public onlyOwner {
        require(
            active != plantingActive,
            "Planting is already in the desired state"
        );
        plantingActive = active;
        emit PlantingActiveChange(plantingActive);
    }

    function setMojoContractAddress(IMojo _mojoContract) public onlyOwner {
        emit MojoContractAddressChange(
            address(mojoContract),
            address(_mojoContract)
        );
        mojoContract = _mojoContract;
    }

    function setMojoSeedContractAddress(IMojoSeed _mojoSeedContract)
        public
        onlyOwner
    {
        emit MojoSeedContractAddressChange(
            address(mojoSeedContract),
            address(_mojoSeedContract)
        );
        mojoSeedContract = _mojoSeedContract;
    }

    function setSproutingDelay(uint256 _sproutingDelay) public onlyOwner {
        emit SproutingDelayChange(sproutingDelay, _sproutingDelay);
        sproutingDelay = _sproutingDelay;
    }

    /**
     * @dev Called by the MojoSeed contract when the user gives approval.
     * This is used to approve the Sprouter contract to "spend" the MojoSeed and transfer it into it's own custody
     * in a single transaction.
     */
    function onApprovalReceived(
        address owner,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        require(plantingActive, "Planting is not active");

        require(
            _msgSender() == address(mojoSeedContract),
            "Can only plant Mojo Seeds"
        );
        require(!mojoContract.exists(tokenId), "Mojo already minted");
        require(owner != address(this), "Seed has already been deposited");

        seeds.allTokens.push(tokenId);
        seeds.allTokensIndex[tokenId] = seeds.allTokens.length - 1;

        seeds.ownedTokens[owner].push(tokenId);
        seeds.ownedTokensIndex[tokenId] = seeds.ownedTokens[owner].length - 1;

        seeds.seedPlantBlockstamp[tokenId] = block.number;

        mojoSeedContract.safeTransferFrom(owner, address(this), tokenId);

        emit MojoSeedPlanted(tokenId, owner);

        return IERC721PayableSpender.onApprovalReceived.selector;
    }

    /**
     * @dev Called by the user to burn the MojoSeed and mint a new Mojo
     */
    function sprout(uint256 seedId, address recipient) public {
        address sender = _msgSender();

        require(!mojoContract.exists(seedId), "Mojo already minted");
        require(isSeedOwner(sender, seedId), "Seed doesn't belong to sender");
        require(
            hasSproutingDelayPassed(seedId),
            "Sprouting delay has not passed"
        );

        _removeSeedFromAllTokensEnumeration(seedId);
        _removeSeedFromOwnerEnumeration(sender, seedId);

        mojoSeedContract.burn(seedId);
        mojoContract.mintById(recipient, seedId);

        emit MojoSprout(seedId, sender, recipient);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function isSeedOwner(address account, uint256 tokenId)
        public
        view
        returns (bool)
    {
        if (seeds.ownedTokens[account].length == 0) {
            return false;
        }

        return
            seeds.ownedTokens[account][seeds.ownedTokensIndex[tokenId]] ==
            tokenId;
    }

    function isSeedPlanted(uint256 tokenId) public view returns (bool) {
        if (seeds.allTokens.length == 0) {
            return false;
        }

        return seeds.allTokens[seeds.allTokensIndex[tokenId]] == tokenId;
    }

    function canSprout(uint256 seedId) public view returns (bool) {
        if (!isSeedPlanted(seedId)) {
            return false;
        }

        return hasSproutingDelayPassed(seedId);
    }

    function hasSproutingDelayPassed(uint256 seedId)
        public
        view
        returns (bool)
    {
        return
            seeds.seedPlantBlockstamp[seedId] + sproutingDelay <= block.number;
    }

    function enumerateSeeds(uint256 start, uint256 count)
        public
        view
        returns (uint256[] memory ids, uint256 total)
    {
        uint256 length = seeds.allTokens.length;
        if (start + count > length) {
            count = length - start;
        }

        ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = seeds.allTokens[start + i];
        }

        return (ids, length);
    }

    function enumerateSeedsOfOwner(
        address account,
        uint256 start,
        uint256 count
    ) public view returns (uint256[] memory ids, uint256 total) {
        uint256 length = seeds.ownedTokens[account].length;
        if (start + count > length) {
            count = length - start;
        }

        ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = seeds.ownedTokens[account][start + i];
        }

        return (ids, length);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721PayableSpender).interfaceId ||
            interfaceId == INTERFACE_ID_ERC173;
    }

    function _removeSeedFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = seeds.allTokens.length - 1;
        uint256 tokenIndex = seeds.allTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = seeds.allTokens[lastTokenIndex];

            seeds.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            seeds.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete seeds.allTokensIndex[tokenId];
        seeds.allTokens.pop();
    }

    function _removeSeedFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = seeds.ownedTokens[from].length - 1;
        uint256 tokenIndex = seeds.ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = seeds.ownedTokens[from][lastTokenIndex];

            seeds.ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            seeds.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete seeds.ownedTokensIndex[tokenId];
        seeds.ownedTokens[from].pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title BasicTimelockController
 * @dev Contract which acts as a timelocked controller
 */
contract BasicTimelockController is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error FailedToSendEther();
error AddressCannotBeZero();

/**
 * @title OwnerWithdrawable
 * @dev Contract where the owner can withdraw eth and erc20 tokens
 */
abstract contract OwnerWithdrawable is Ownable {
    event Withdrawal(
        address indexed receiver,
        uint256 ethAmount,
        address[] erc20Addresses,
        uint256[] erc20Amounts
    );

    using SafeERC20 for IERC20;

    function withdraw(
        address receiver,
        uint256 ethAmount,
        address[] memory erc20Addresses,
        uint256[] memory erc20Amounts
    ) external onlyOwner {
        if (receiver == address(0)) {
            revert AddressCannotBeZero();
        }

        //If eth amount to withdraw is not zero then withdraw it
        if (ethAmount != 0) {
            (bool sent, ) = receiver.call{value: ethAmount}("");

            if (!sent) {
                revert FailedToSendEther();
            }
        }

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            uint256 amount = erc20Amounts[i];

            IERC20 token = IERC20(erc20Addresses[i]);

            token.safeTransfer(receiver, amount);
        }

        emit Withdrawal(receiver, ethAmount, erc20Addresses, erc20Amounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721MintManagement.sol";
import "../../../royalties/CustomRoyalties.sol";
import "../../../access/OwnableWithTempOwnership.sol";
import "../../../common/meta-transactions/RelayRecipientAndContextMixin.sol";

/**
 * @title PlanetMojoERC721Base
 * @dev Base ERC721 contract for Planet Mojo NFTs
 */
abstract contract PlanetMojoERC721Base is ERC721MintManagement, CustomRoyalties, OwnableWithTempOwnership {
    constructor(
        address _owner, 
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    )
        ERC721Tradable(_name, _symbol) 
        OwnableWithTempOwnership(_owner) {
        _setBaseTokenURI(_baseURI);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev Allow or disallow given account to mint new tokens and set TokenURIs
     */
    function setMinter(address account, bool trusted) public onlyOwner {
        _setMinter(account, trusted);
    }
  
    /**
    * @dev Allow or disallow given accounts to mint new tokens and set TokenURIs
    */
    function setMinters(address[] memory _minters, bool[] memory trusted) public onlyOwner {
        _setMinters(_minters, trusted);
    }

    /**
     * @dev Expose internal _setTokenIdCounter to the owner of the contract
     * @param _tokenIdCounter the number of the next token to mint when minting with auto-increment
     */
    function setTokenIdCounter(uint256 _tokenIdCounter) public onlyOwner {
        _setTokenIdCounter(_tokenIdCounter);
    }

    /**
     * @dev Expose internal _setTrustedForwarder to the owner of the contract
     */
    function setTrustedForwarder(address forwarder, bool trusted) public onlyOwner {
        _setTrustedForwarder(forwarder, trusted);
    }

    /**
     * @dev Expose internal _setRoyaltiesForAll to the owner of the contract
     */
    function setRoyaltiesForAll(address payable recipientAddress, uint96 percentageBasisPoints) public onlyOwner {
        _setRoyaltiesForAll(recipientAddress, percentageBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Tradable, Ownable, CustomRoyalties) returns (bool) {
        return ERC721Tradable.supportsInterface(interfaceId) ||
            Ownable.supportsInterface(interfaceId) ||
            CustomRoyalties.supportsInterface(interfaceId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return RelayRecipientAndContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Tradable.sol";

error OnlyAuthorizedMinter();
error NonMatchingArgumentLengths();

/**
 * @title ERC721MintManagement
 * @dev Contract that adds management for custom minter on top of the ERC721Tradable
 */
abstract contract ERC721MintManagement is ERC721Tradable {
    event MinterPrivilegesChange(address indexed account, bool trusted);
    
    mapping(address => bool) private minters;

    /**
     * @dev Checks if a given account is a minter
     */
    function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

    /**
     * @dev Mints a token to a given address
     */
    function mintTo(address to) public onlyMinters returns(uint256 tokenId) {
        return _mintTo(to);
    }

    /**
     * @dev Mints a token with a given ID to a given address
     */
    function mintById(address to, uint256 tokenId) public onlyMinters {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Mints many tokens to many accounts
     * Can specify a different number of tokens for each account
     */
    function mintMany(address[] memory recipients, uint256[] memory tokenCounts) public onlyMinters {
        for(uint256 i = 0; i < recipients.length; i++) {
            uint256 cnt = tokenCounts[i];

            for(uint256 j = 0; j < cnt; j++) {
                _mintTo(recipients[i]);
            }
        }
    }

    /**
     * @notice Mints many tokens to many accounts
     * Can specify different tokenIds for each account
     */
    function mintManyByIds(address[] memory recipients, uint256[][] memory tokenIds) public onlyMinters {
        for(uint256 i = 0; i < recipients.length; i++) {
            uint256 cnt = tokenIds[i].length;

            for(uint256 j = 0; j < cnt; j++) {
                _safeMint(recipients[i], tokenIds[i][j]);
            }
        }
    }

    /**
     * @dev Sets the token URI for a given token ID
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyMinters {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Allow or disallow given account to mint new tokens and set TokenURIs
     */
    function _setMinter(address account, bool trusted) internal {
        minters[account]= trusted;

        emit MinterPrivilegesChange(account, trusted);
    }

    /**
     * @dev Allow or disallow given accounts to mint new tokens and set TokenURIs
     */
    function _setMinters(address[] memory _minters, bool[] memory trusted) internal {
        if(_minters.length != trusted.length) {
            revert NonMatchingArgumentLengths();
        }

        for(uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = trusted[i];
            emit MinterPrivilegesChange(_minters[i], trusted[i]);
        }
    }

    /**
    * @dev Throws if called by any account other than an authorized minter.
    */
    modifier onlyMinters() {
        if(!minters[_msgSender()]) {
            revert OnlyAuthorizedMinter();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./rarible/RoyaltiesV2.sol";
import "./rarible/LibPart.sol";
import "./rarible/LibRoyaltiesV2.sol";
import "./IERC2981.sol";

/**
 * @title CustomRoyalties
 * @dev Contract for Rarible and EIP2981 royalties
 */
abstract contract CustomRoyalties is RoyaltiesV2, IERC2981 {
    event RoyaltiesForAllSet(
        address prevRecipient,
        uint256 prevRoyalties,
        address newRecipient,
        uint256 newRoyalties
    );

    address payable public royaltyRecipient;
    uint256 public royaltyPercentageBasisPoints;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev Sets royalties for all tokens to be paid to the given address
     */
    function _setRoyaltiesForAll(
        address payable recipientAddress,
        uint96 percentageBasisPoints
    ) internal {
        emit RoyaltiesForAllSet(
            royaltyRecipient,
            royaltyPercentageBasisPoints,
            recipientAddress,
            percentageBasisPoints
        );

        royaltyRecipient = recipientAddress;
        royaltyPercentageBasisPoints = percentageBasisPoints;
    }

    /**
     * @dev Retrieve royalties for a given token for Rarible
     */
    function getRaribleV2Royalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);

        _royalties[0] = LibPart.Part(
            royaltyRecipient,
            uint96(royaltyPercentageBasisPoints)
        );

        return _royalties;
    }

    /**
     * @dev Retrieve royalty info using the ERC2981 standard
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (royaltyRecipient == address(0)) {
            return (address(0), 0);
        }

        return (
            royaltyRecipient,
            (_salePrice * royaltyPercentageBasisPoints) / 10000
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ||
            interfaceId == _INTERFACE_ID_ERC2981;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

error OnlRootOwnerCanRevoke();

/**
 * @title OwnableWithTempOwnership
 * @dev Extends the OpenZepellin's Ownable contract to allow for "temporary" ownership.
 * This is used to prove ownership of the contract to external services such as OpenSea which don't work with on-chain wallets.
 * The ownership is "delegated" to an external account which can interact with those services.
 * Temporary owners have no authority to perform owner-only functions
 */
abstract contract OwnableWithTempOwnership is Ownable {
    event TempOwnerSet(address indexed tempOwner);
    event TempOwnerRevoked(address indexed tempOwner);
    event RootOwnerChange(address indexed rootOwner);
    //While the contract is temporarily owned by an account, this variable indicates the true/root owner
    //Otherwise it is 0x0
    address public rootOwner;

    constructor(address _owner) Ownable(_owner) {}

    function setTempOwner(address account) public onlyOwner {
        //If no temp owner is set, then the owner is the 'real' owner
        //so we should set them as root
        if (rootOwner == address(0)) {
            _setRootOwner(owner());
        }

        //Call super to avoid setting the root owner to 0x0
        super.transferOwnership(account);
        emit TempOwnerSet(account);
    }

    function revokeTempOwner() public {
        if (rootOwner != _msgSender()) {
            revert OnlRootOwnerCanRevoke();
        }

        emit TempOwnerRevoked(owner());
        //Call super to avoid setting the root owner to 0x0
        super.transferOwnership(rootOwner);

        _setRootOwner(address(0));
    }

    function tempOwner() public view returns (address) {
        return rootOwner != address(0) ? owner() : address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * This was overriden to prevent the rootOwner from keeping access after transferring ownership
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);

        _setRootOwner(address(0));
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * This was overriden to prevent the rootOwner from keeping access after renouncing ownership
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));

        _setRootOwner(address(0));
    }

    /**
     * @dev Throws if called by any account other than the owner.
     * Temporary owners have no authority to perform owner-only functions.
     */
    modifier onlyOwner() override {
        address sender = _msgSender();

        //If a root owner is set then the owner() is a temporary owner
        //Only the root owner (real owner) can perform owner-only functions
        if (rootOwner != address(0)) {
            if (rootOwner != sender) {
                revertOwnable();
            }
        } else {
            //If a root owner is not set, then there is no temporary owner and the owner() is the real owner
            if (owner() != sender) {
                revertOwnable();
            }
        }
        _;
    }

    /**
     * @dev Sets the root owner of the contract.
     */
    function _setRootOwner(address newRootOwner) private {
        if (rootOwner != newRootOwner) {
            rootOwner = newRootOwner;
            emit RootOwnerChange(newRootOwner);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./RelayRecipient.sol";

abstract contract RelayRecipientAndContextMixin is RelayRecipient {
    /**
     * Return the sender of this call.
     * if the call came through a trusted forwarder (EIP-2771), return the original sender.
     * if the call came from the contract itself (EIP-712 meta transactions), return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                sender := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else if (msg.sender == address(this)) {
            // If the sender is the contract itself, then it's using the EIP-712 meta transactions.
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }

        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../common/meta-transactions/RelayRecipientAndContextMixin.sol";
import "../../../common/meta-transactions/NativeMetaTransaction.sol";
import "../payable/ERC721Payable.sol";

/**
 * @title ERC721Tradable
 * @dev ERC721 contract that whitelists a the OpenSea proxies, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721Payable, ERC721Enumerable, ERC721Burnable, RelayRecipientAndContextMixin, NativeMetaTransaction {
    event TokenIdCounterChange(uint256 prevCounter, uint256 newCounter);
    event BaseTokenURIChange(string prevURI, string newURI);
    event TokenURIChange(uint256 indexed tokenId, string prevURI, string newURI);
  
    /**
     * @dev Used to track of the next token ID when minting by auto-increment
     */ 
    uint256 public tokenIdCounter;
    /**
     * @dev A settable base URI for the token metadata
     */ 
    string public baseTokenURI;
    
    /**
     * @dev Used to track token URI per token
     */ 
    mapping(uint256 => string) public tokenURIs;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        tokenIdCounter = 1;
        _initializeEIP712(_name);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return bytes(tokenURIs[tokenId]).length != 0
            ? tokenURIs[tokenId] 
            : string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Set the token ID counter to a specific value
     * @param _tokenIdCounter the number of the next token to mint when minting with auto-increment
     */
    function _setTokenIdCounter(uint256 _tokenIdCounter) internal {
        emit TokenIdCounterChange(tokenIdCounter, _tokenIdCounter);
        tokenIdCounter = _tokenIdCounter;
    }

    /**
     * @dev Set baseTokenURI that is the base URI for token metadata
     * @param uri the base URI for token metadata
     */
    function _setBaseTokenURI(string memory uri) internal {
        emit BaseTokenURIChange(baseTokenURI, uri);
        baseTokenURI = uri;
    }

    /**
     * @dev Mints a token with a given ID to an address
     */
    function _mintTo(address to) internal virtual returns(uint256 tokenId) {
        tokenId = tokenIdCounter;
        
        _safeMint(to, tokenId);
        tokenIdCounter++;

        return tokenId;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Sets the token URI for a given token ID
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        emit TokenURIChange(tokenId, tokenURIs[tokenId], _tokenURI);
        tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Payable, ERC721, ERC721Enumerable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
    ) internal virtual {}

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721Payable.sol";
import "./IERC721PayableSpender.sol";
import "./IERC721PayableReceiver.sol";

error NonERC721PayableSpenderImplementer();
error NonERC721PayableReceiverImplementer();

abstract contract ERC721Payable is ERC721, IERC721Payable {
    /**
     * @dev Approve the passed address to spend the specified token on behalf of sender
     * and then call `onApprovalReceived` on spender.
     * @param spender The address of the spender.
     * @param tokenId The token ID to be approved.
     */
    function approveAndCall(address spender, uint256 tokenId) public override virtual {
        _approveAndCall(spender, tokenId, new bytes(0));
    }

    /**
     * @dev Approve the passed address to spend the specified token on behalf of sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address of the spender.
     * @param tokenId uint256 The token ID to be approved.
     * @param data bytes Additional data with no specified format, sent in call to `to`
     */
    function approveAndCall(address spender, uint256 tokenId, bytes memory data) public override virtual{
        _approveAndCall(spender, tokenId, data);
    }

    /**
     * @dev Transfer a token from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send the token from  
     * @param to address The address which you want to transfer to
     * @param tokenId uint256 The token ID to be transferred
     */
    function transferFromAndCall(address from, address to, uint256 tokenId) public override virtual {
        _transferFromAndCall(from, to, tokenId, new bytes(0));
    }

    /**
     * @dev Transfer a token from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send the token from  
     * @param to address The address which you want to transfer to
     * @param tokenId uint256 The token ID to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     */
    function transferFromAndCall(address from, address to, uint256 tokenId, bytes memory data) public override virtual {
        _transferFromAndCall(from, to, tokenId, data);
    }

    function _approveAndCall(address spender, uint256 tokenId, bytes memory data) private {
      approve(spender, tokenId);

      bytes4 response = IERC721PayableSpender(spender).onApprovalReceived(_msgSender(), tokenId, data);

      if(response != IERC721PayableSpender.onApprovalReceived.selector) {
          revert NonERC721PayableSpenderImplementer();
      }
    }

    function _transferFromAndCall(address from, address to, uint256 tokenId, bytes memory data) private {
        safeTransferFrom(from, to, tokenId);

        bytes4 response = IERC721PayableReceiver(to).onTransferReceived(_msgSender(), from, tokenId, data);

        if(response != IERC721PayableReceiver.onTransferReceived.selector) {
            revert NonERC721PayableReceiverImplementer();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Payable).interfaceId || 
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function approve(address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

/**
 * @dev A base contract to be inherited by any contract that wants to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract RelayRecipient {
    /**
     * Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event TrustedForwarderSet(address indexed forwarder, bool trusted);

    /**
     * @dev Forwarders we accept calls from
     */
    mapping(address => bool) public trustedForwarders;

    function isTrustedForwarder(address forwarder) public view returns(bool) {
        return trustedForwarders[forwarder];
    }

    function _setTrustedForwarder(address forwarder, bool trusted) internal {
        trustedForwarders[forwarder] = trusted;
        emit TrustedForwarderSet(forwarder, trusted);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Payable {
    /**
     * @dev Approve the passed address to spend the specified token on behalf of sender
     * and then call `onApprovalReceived` on spender.
     * @param spender The address of the spender.
     * @param tokenId The token ID to be approved.
     */
    function approveAndCall(address spender, uint256 tokenId) external;

    /**
     * @dev Approve the passed address to spend the specified token on behalf of sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address of the spender.
     * @param tokenId uint256 The token ID to be approved.
     * @param data bytes Additional data with no specified format, sent in call to `to`
     */
    function approveAndCall(address spender, uint256 tokenId, bytes memory data) external;

    /**
     * @dev Transfer a token from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send the token from  
     * @param to address The address which you want to transfer to
     * @param tokenId uint256 The token ID to be transferred
     */
    function transferFromAndCall(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfer a token from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send the token from  
     * @param to address The address which you want to transfer to
     * @param tokenId uint256 The token ID to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     */
    function transferFromAndCall(address from, address to, uint256 tokenId, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721PayableSpender {
    function onApprovalReceived(address owner, uint256 tokenId, bytes memory data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721PayableReceiver {
    function onTransferReceived(address operator, address from, uint256 tokenId, bytes memory data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

interface RoyaltiesV2 {
    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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
 * @notice This contract is the OpenZeppelin Ownable contract with two changes
 * First - The constructor takes an "initialOwner" address to use as the first owner instead of the message sender
 * This allows the contract to be deployed by an account other than the owner
 * Second - The "onlyOwner" modifier has been made virtual so that it can be overridden by the inheriting contract
 */
abstract contract Ownable is Context, IERC165 {
    //The ERC-165 identifier for the ERC-173 Ownable standard is 0x7f5828d0
    bytes4 private constant INTERFACE_ID_ERC173 = 0x7f5828d0;

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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
    modifier onlyOwner() virtual {
        if (owner() != _msgSender()) {
            revertOwnable();
        }
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_ERC173;
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

    /**
     * @dev Using this to lower contract size
     */
    function revertOwnable() internal pure {
        revert("Ownable: caller is not the owner");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";
import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC1155/IERC1155Receiver.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl, IERC721Receiver, IERC1155Receiver {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`, and a list of
     * initial proposers and executors. The proposers receive both the
     * proposer and the canceller role (for backward compatibility). The
     * executors receive the executor role.
     *
     * NOTE: At construction, both the deployer and the timelock itself are
     * administrators. This helps further configuration of the timelock by the
     * deployer. After configuration is done, it is recommended that the
     * deployer renounces its admin position and relies on timelocked
     * operations to perform future maintenance.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], payloads[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}