// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./MasterchiefControl.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/INFT.sol";
import "./interfaces/INifty.sol";
import "./interfaces/IToken.sol";

contract GenerativeController is MasterchiefControl, ERC1155Holder {
    INFT public immutable nft;
    INifty public immutable nifty;

    uint256 public denominator;

    uint256[] private traitAmounts;
    bool private mintLocked;

    uint256 private constant UNLOCK_DELAY_SECONDS_MIN = 2592000;
    uint256 private constant CLAIM_DELAY_BLOCKS_MIN = 86400 / 3;
    uint256 private constant TRAITS_LENGTH = 5;

    bytes4 private constant SELL_SIG = bytes4(0xade79c7a);

    mapping (int256 => uint256) private unlockDelay;
    mapping (address => uint256) private share;
    mapping (address => mapping (uint256 => bool)) private hasPotentialNftIdDelegated;
    mapping (address => mapping (int256 => uint256[])) private potentialNftIdsDelegated;

    event Delegated(
        uint256 indexed nftId,
        address indexed from,
        address indexed to
    );

    event Bought(
        uint256 indexed nftId,
        address indexed sender,
        address indexed recipient,
        uint256 tokenAmount
    );

    event Sold(
        uint256 indexed nftId,
        address indexed from,
        uint256 tokenAmount,
        uint256 tokenAmountClaimed
    );

    constructor(
        INFT nft_,
        INifty nifty_,
        IMasterchief masterchief_
    )
        MasterchiefControl(masterchief_)
    {
        nft = nft_;
        nifty = nifty_;

        traitAmounts = new uint256[](TRAITS_LENGTH);
        for (uint256 i = 0; i < traitAmounts.length; i++) traitAmounts[i] = 1;

        approve();
    }

    receive() external payable {}

    fallback() external payable {}

    function rebalance(
        int256 amount
    )
        external
        onlyMasterchief
    {}

    function buy(
        bytes calldata args,

        address sender,
        uint256 amountInMax,
        uint8 verifier
    )
        onlyMasterchief
        external
    {
        require(verifier == 0);

        (
            uint256 nftId,
            address recipient,
            address delegatee,
            uint256 deadline
        ) = abi.decode(args, (uint256, address, address, uint256));

        (
            address owner,
            uint256 delay,
            uint256 numerator,
            uint256 unlockAt,
            uint256[] memory traits,
            int256 category
        ) = _buyParams(nftId);

        require(
            owner == address(this) &&
            recipient != address(this) &&
            traits.length == TRAITS_LENGTH,
            'GenerativeController: INVALID_OWNER_OR_NFT'
        );

        denominator += numerator;
        share[delegatee] += numerator;

        uint256 tokenAmount = _buyTraits(traits, amountInMax, deadline);

        if(recipient != delegatee) masterchief.initShareholder(recipient);
        _potentialNftIdDelegated(delegatee, category, nftId);

        nft.safeTransferFrom(address(this), recipient, nftId, 1, abi.encode(
            recipient,
            delegatee,
            delay,
            numerator,
            block.number,
            0,
            unlockAt,
            traits
        ));

        emit Bought(nftId, sender, recipient, tokenAmount);
    }

    function claim(
        uint256 nftId,
        address recipient,
        uint256 pathId,
        uint256 amountOutMin
    )
        external
    {
        (
            address owner,
            address delegatee,
            uint256 delay,
            uint256 numerator,
            uint256 blockNumber,
            uint256 tokenAmountClaimed,
            uint256 unlockAt,
            uint256[] memory traits
        ) = abi.decode(nft.nftData(nftId).params, (address, address, uint256, uint256, uint256, uint256, uint256, uint256[]));

        require(
            delegatee == msg.sender &&
            numerator > 0,
            'GenerativeController: INVALID_NFT_OR_DELEGATEE'
        );

        tokenAmountClaimed += _claim(
            nftId,
            recipient,
            blockNumber,
            delay,
            numerator,
            pathId,
            amountOutMin
        );

        nft.update(nftId, abi.encode(
            owner,
            delegatee,
            delay,
            numerator,
            block.number,
            tokenAmountClaimed,
            unlockAt,
            traits
        ));
    }

    function delegate(
        uint256 nftId,
        address delegatee
    )
        external
    {
        INFT.Nft memory nft_ = nft.nft(nftId, address(0));
        (
            address owner,
            address delegateeFrom,
            uint256 delay,
            uint256 numerator,
            uint256 blockNumber,
            uint256 tokenAmountClaimed,
            uint256 unlockAt,
            uint256[] memory traits
        ) = abi.decode(nft_.params, (address, address, uint256, uint256, uint256, uint256, uint256, uint256[]));

        require(
            owner == msg.sender && numerator > 0,
            'GenerativeController: INVALID_OWNER'
        );

        blockNumber = block.number;

        nft.update(nftId, abi.encode(
            owner,
            delegatee,
            delay,
            numerator,
            block.number,
            tokenAmountClaimed,
            unlockAt,
            traits
        ));

        if(delegateeFrom != delegatee) {
            if(share[delegateeFrom] > numerator) {
                share[delegateeFrom] -= numerator;
            } else {
                share[delegateeFrom] = 0;
            }
            share[delegatee] += numerator;

            masterchief.initShareholder(delegatee);
            _potentialNftIdDelegated(delegatee, nft_.category, nftId);

            emit Delegated(nftId, delegateeFrom, delegatee);
        }
    }

    function nftData(
        INFT.Data calldata nftData_,
        INFT.Id calldata, // nftId
        address sender,
        address, // from
        address to,
        uint256, // amount
        bytes calldata data
    )
        external
        returns (INFT.Data memory)
    {
        require(msg.sender == address(nft));

        (
            , // address owner
            address delegatee,
            uint256 delay,
            uint256 numerator,
            , //uint256 blockNumber
            uint256 tokenAmountClaimed,
            uint256 unlockAt,
            uint256[] memory traits
        ) = abi.decode(nftData_.params, (address, address, uint256, uint256, uint256, uint256, uint256, uint256[]));

        if(to == address(this)) {
            _sell(nftData_, unlockAt, tokenAmountClaimed, traits, data);

            denominator -= numerator;
            if(share[delegatee] > numerator) {
                share[delegatee] -= numerator;
            } else {
                share[delegatee] = 0;
            }

            delegatee = address(this);
            tokenAmountClaimed = 0;
            unlockAt = 0;
        } else if(sender == address(this)) {
            // buy
            return INFT.Data({
                id: 0,
                updatedAt: block.timestamp,
                params: data
            });
        } else {
            // send
            masterchief.initShareholder(to);
        }

        return INFT.Data({
            id: 0,
            updatedAt: block.timestamp,
            params: abi.encode(
                to,
                delegatee,
                delay,
                numerator,
                block.number,
                tokenAmountClaimed,
                unlockAt,
                traits
            )
        });
    }

    function shareholder(
        address account,
        bytes calldata params
    )
        public
        view
        returns (IMasterchief.ShareholderExtended memory)
    {
        int256[][] memory categories = new int256[][](1);
        uint256[] memory nftIds;
        uint256[] memory nftIdsDelegated;

        if(params.length > 0) {
            categories[0] = abi.decode(params, (int256[]));

            address[] memory controllers = new address[](1);
            controllers[0] = address(this);

            nftIds = nft.idBatch(account, controllers, categories);
            nftIdsDelegated = _nftIdDelegatedBatch(account, categories[0]);
        }

        return masterchief.shareholderExtended(
            account,
            0,
            0,
            share[account],
            denominator,
            abi.encode(
                nftIds,
                nftIdsDelegated
            )
        );
    }

    function shareholderBatch(
        address[] calldata accounts,
        bytes[] calldata params
    )
        external
        view
        returns (IMasterchief.ShareholderExtended[] memory)
    {
        IMasterchief.ShareholderExtended[] memory shareholders = new IMasterchief.ShareholderExtended[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) shareholders[i] = shareholder(accounts[i], params[i]);
        return shareholders;
    }

    function totalPotentialNftIdsDelegated(
        address account,
        int256 category
    )
        external
        view
        returns (uint256)
    {
        return potentialNftIdsDelegated[account][category].length;
    }

    function potentialNftIdDelegatedBatch(
        address account,
        int256 category,
        uint256 skip,
        uint256 total
    )
        external
        view
        returns (uint256[] memory)
    {
        total = (total == 0) ? potentialNftIdsDelegated[account][category].length - skip : total;
        uint256[] memory nftIds = new uint256[](total);
        uint256 c;
        for (uint256 i = skip; i < (skip + total); i++) {
            nftIds[c] = potentialNftIdsDelegated[account][category][i];
            c++;
        }
        return nftIds;
    }

    function _nftIdDelegatedBatch(
        address delegatee,
        int256[] memory categories
    )
        internal
        view
        returns (uint256[] memory)
    {
        uint256 c;
        for (uint256 i = 0; i < categories.length; i++) {
            c += potentialNftIdsDelegated[delegatee][categories[i]].length;
        }

        uint256[] memory nftIds = new uint256[](c);
        c = 0;
        for (uint256 i = 0; i < categories.length; i++) {
            for (uint256 y = 0; y < potentialNftIdsDelegated[delegatee][categories[i]].length; y++) {
                nftIds[c] = potentialNftIdsDelegated[delegatee][categories[i]][y];
                c++;
            }
        }

        INFT.Data[] memory datas = nft.nftDataBatch(nftIds);
        c = 0;
        for (uint256 i = 0; i < datas.length; i++) {
            (
                , // address owner
                address delegatee_
            ) = abi.decode(datas[i].params, (address, address));

            if(delegatee == delegatee_) {
                c++;
            } else {
                datas[i].id = 0;
            }
        }

        nftIds = new uint256[](c);
        c = 0;
        for (uint256 i = 0; i < datas.length; i++) {
            if(datas[i].id > 0) {
                nftIds[c] = datas[i].id;
                c++;
            }
        }

        return nftIds;
    }

    function _potentialNftIdDelegated(
        address delegatee,
        int256 category,
        uint256 nftId
    )
        internal
    {
        if(!hasPotentialNftIdDelegated[delegatee][nftId]) {
            hasPotentialNftIdDelegated[delegatee][nftId] = true;
            potentialNftIdsDelegated[delegatee][category].push(nftId);
        }
    }

    function _claim(
        uint256 nftId,
        address recipient,
        uint256 blockNumber,
        uint256 delay,
        uint256 numerator,
        uint256 pathId,
        uint256 amountOutMin
    )
        internal
        returns (uint256)
    {
        uint256[] memory amounts = masterchief.claim(
            address(uint160(nftId)),
            msg.sender,
            recipient,
            blockNumber,
            delay,
            numerator,
            denominator,
            pathId,
            amountOutMin
        );

        if(amounts.length > 0) return amounts[0];
        return 0;
    }

    function _buyParams(
        uint256 nftId
    )
        internal
        view
        returns (address, uint256, uint256, uint256, uint256[] memory, int256)
    {
        INFT.Nft memory nft_ = nft.nft(nftId, address(0));
        (
            address owner,
            , // address delegatee,
            uint256 delay,
            uint256 numerator,
            , // uint256 blockNumber,
            , // uint256 tokenAmountClaimed,
            , // uint256 unlockAt,
            uint256[] memory traits
        ) = abi.decode(nft_.params, (address, address, uint256, uint256, uint256, uint256, uint256, uint256[]));

        return (owner, delay, numerator, block.timestamp + unlockDelay[nft_.category], traits, nft_.category);
    }

    function _buyTraits(
        uint256[] memory traits,
        uint256 amountInMax,
        uint256 deadline
    )
        internal
        returns (uint256)
    {
        uint256 tokenAmount;
        uint256[] memory tokenAmounts = nifty.buyTokens(
            traits,
            traitAmounts,
            amountInMax,
            deadline,
            address(this),
            new address[](0),
            new uint256[](0)
        );
        for (uint256 i = 0; i < tokenAmounts.length; i++) tokenAmount += tokenAmounts[i];
        return tokenAmount;
    }

    function _sell(
        INFT.Data calldata nftData_,
        uint256 unlockAt,
        uint256 tokenAmountClaimed,
        uint256[] memory traits,
        bytes calldata data
    )
        internal
    {
        (
            bytes4 sig,
            INifty.SellTokensObj memory sellTokensObj,
            address recipient,
            uint256 pathId,
            uint256 amountOutMin
        ) = abi.decode(data, (bytes4, INifty.SellTokensObj, address, uint256, uint256));

        require(
            sig == SELL_SIG &&
            sellTokensObj.recipient == address(masterchief) &&
            traits.length == TRAITS_LENGTH &&
            unlockAt < block.timestamp,
            'GenerativeController: INVALID_SELL_DATA_OR_LOCKED'
        );

        uint256 tokenAmount;
        uint256[] memory tokenAmounts = nifty.getPrice_tokenToCurrency(
            traits,
            traitAmounts
        );
        for (uint256 i = 0; i < tokenAmounts.length; i++) tokenAmount += tokenAmounts[i];

        nft.safeBatchTransferFrom(
            address(this),
            address(nifty),
            traits,
            traitAmounts,
            data
        );

        masterchief.swapTokenFor(
            pathId,
            tokenAmount,
            amountOutMin,
            sellTokensObj.deadline,
            recipient
       );

       emit Sold(nftData_.id, msg.sender, tokenAmount, tokenAmountClaimed);
    }

    function mintBatch(
        int256[] calldata categories,
        uint256[] calldata editions,
        uint256[] calldata amounts,
        bytes[] memory params
    )
        external
    {
        require(msg.sender == masterchief.creator() && !mintLocked);

        address[] memory accounts = new address[](categories.length);
        uint256[] memory ids = new uint256[](categories.length);
        bytes[] memory datas = new bytes[](categories.length);
        for (uint256 i = 0; i < categories.length; i++) {
            if(categories[i] < 0) {
                (
                    address owner,
                    address delegatee,
                    uint256 delay,
                    uint256 numerator,
                    uint256 blockNumber,
                    uint256 tokenAmountClaimed,
                    uint256 unlockAt,
                    uint256[] memory traits
                ) = abi.decode(params[i], (address, address, uint256, uint256, uint256, uint256, uint256, uint256[]));

                accounts[i] = address(this);

                require(
                    amounts[i] == 1 &&
                    owner == accounts[i] &&
                    delegatee == accounts[i] &&
                    delay > CLAIM_DELAY_BLOCKS_MIN &&
                    numerator > 0 &&
                    blockNumber == 0 &&
                    tokenAmountClaimed == 0 &&
                    unlockAt == 0 &&
                    traits.length == traitAmounts.length
                );
            } else {
                require(params[i].length == 0 && amounts[i] > 1);
                accounts[i] = msg.sender;
            }
        }

        nft.mintBatch(
            accounts,
            ids,
            amounts,
            categories,
            editions,
            datas,
            params
        );
    }

    function unlockDelayBatch(
        int256[] calldata categories
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory unlockDelays = new uint256[](categories.length);
        for (uint256 i = 0; i < categories.length; i++) {
            unlockDelays[i] = unlockDelay[categories[i]];
        }

        return unlockDelays;
    }

    function setUnlockDelayBatch(
        int256[] calldata categories,
        uint256[] calldata unlockDelays
    )
        external
        onlyTimelock
    {
        for (uint256 i = 0; i < categories.length; i++) {
            require(unlockDelays[i] >= UNLOCK_DELAY_SECONDS_MIN);

            unlockDelay[categories[i]] = unlockDelays[i];
        }
    }

    function lockMint()
        external
    {
        require(msg.sender == masterchief.creator());
        mintLocked = true;
    }

    function approve()
        public
    {
        IToken(nifty.getCurrencyInfo()).approve(address(nifty), 0);
        IToken(nifty.getCurrencyInfo()).approve(address(nifty), type(uint256).max);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IMasterchief.sol";

contract MasterchiefControl {
    IMasterchief public masterchief;

    constructor(
        IMasterchief masterchief_
    )
    {
        masterchief = masterchief_;
    }

    modifier onlyMasterchief {
        require(address(masterchief) == msg.sender); _;
    }

    modifier onlyTimelock {
        require(masterchief.timelock() == msg.sender); _;
    }

    function totalShareholders()
        external
        view
        returns(uint256)
    {
        return masterchief.totalShareholders();
    }

    function shareholderAccountBatch(
        uint256 skip,
        uint256 total
    )
        external
        view
        returns(address[] memory)
    {
        return masterchief.shareholderAccountBatch(skip, total);
    }

    function setMasterchief(
        IMasterchief masterchief_
    )
        external
        onlyTimelock
    {
        require(masterchief_.timelock() == msg.sender);
        masterchief = masterchief_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface INFT {
    struct Nft {
        uint256 id;
        uint256 index;
        uint256 edition;
        uint256 total;
        uint256 balance;
        uint256 createdAt;
        uint256 updatedAt;
        int256 category;
        address controller;
        bytes params;
    }

    struct Id {
        address controller;
        int256 category;
        uint256 createdAt;
        uint256 edition;
        uint256 index;
        uint256 total;
    }

    struct Data {
        uint256 id;
        uint256 updatedAt;
        bytes params;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        int256 category,
        uint256 edition,
        bytes memory data,
        bytes memory params
    ) external returns (uint256);

    function mintBatch(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts,
        int256[] memory categories,
        uint256[] memory editions,
        bytes[] memory datas,
        bytes[] memory params
    ) external returns (uint256[] memory);

    function update(
        uint256 id,
        bytes calldata params
    ) external;

    function updateBatch(
        uint256[] calldata ids,
        bytes[] calldata params
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address[] calldata accounts,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    function idBatch(
        address account,
        address[] memory controllers,
        int256[][] memory categories
    ) external view returns (uint256[] memory);

    function nft(
        uint256 id,
        address account
    ) external view returns (INFT.Nft memory);

    function nftBatch(
        uint256[] calldata ids,
        address account
    ) external view returns (INFT.Nft[] memory);

    function nftData(
        uint256 id
    ) external view returns (INFT.Data memory);

    function nftDataBatch(
        uint256[] calldata ids
    ) external view returns (INFT.Data[] memory);

    function totalPotentialIds(
        address account,
        address controller,
        int256 category
    ) external view returns (uint256);

    function potentialIdBatch(
        address account,
        address controller,
        int256 category,
        uint256 skip,
        uint256 total
    ) external view returns (uint256[] memory);

    function totalSupply(
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface INifty {
    struct SellTokensObj {
        address recipient;
        uint256 minCurrency;
        address[] extraFeeRecipients;
        uint256[] extraFeeAmounts;
        uint256 deadline;
    }

    function buyTokens(
        uint256[] memory _tokenIds,
        uint256[] memory _tokensBoughtAmounts,
        uint256 _maxCurrency,
        uint256 _deadline,
        address _recipient,
        address[] memory _extraFeeRecipients,
        uint256[] memory _extraFeeAmounts
    ) external returns (uint256[] memory);

    function getCurrencyInfo() external view returns (address);

    function getPrice_tokenToCurrency(
        uint256[] calldata _ids,
        uint256[] calldata _tokensSold
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IToken {
    function totalSupply() external view returns (uint256);

    function buyTaxPermille() external view returns (uint256);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function rebalance(
        int256 amount,
        address account
    ) external;

    function sync(
        address pair,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMasterchief {
    function token() external view returns (address);

    function governanceToken() external view returns (address);

    function creator() external view returns (address);

    function deputy() external view returns (address);

    function timelock() external view returns (address);

    function sync() external;

    struct ShareholderExtended {
        address controller;
        address account;
        uint256 createdAt;
        uint256 delay;
        uint256 share;
        uint256 shares;
        uint256 totalClaims;
        uint256 tokenAmountClaimed;
        uint256 tokenAmountUnclaimed;
        bytes params;
    }

    struct ControllerExtended {
        address controller;
        uint256 numerator;
        uint256 tokenAmountClaimed;
        uint256 tokenAmountUnclaimed;
    }

    function totalShareholders() external view returns(uint256);

    function shareholderExtended(
        address account,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares,
        bytes memory params
    ) external view returns (ShareholderExtended memory);

    function shareholderAccountBatch(
        uint256 skip,
        uint256 total
    ) external view returns(address[] memory);

    function shareholderExtendedBatch(
        address[] memory accounts,
        uint256[] calldata blockNumbers,
        uint256[] memory delays,
        uint256[] memory shares,
        bytes[] memory params,
        uint256 shares_
    ) external view returns (ShareholderExtended[] memory);

    function unclaimed(
        address controller,
        address ref,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares
    ) external view returns (uint256);

    function claim(
        address ref,
        address account,
        address recipient,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares,
        uint256 pathId,
        uint256 amountOutMin
    ) external returns (uint256[] memory amounts);

    function initShareholder(
        address account
    ) external;

    function swapTokenFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    ) external;

    function swapGovernanceTokenFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient,
        address delegatee
    ) external;

    function isController(
        address controller
    ) external view returns (bool);

    function isDeputySelector(
        bytes4 selector
    ) external view returns (bool);

    function controllerAddressBatch() external view returns(address[] memory);

    function controllerBatch() external view returns(ControllerExtended[] memory);

    function pathBatch() external view returns(address[][] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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