// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMortgageControl.sol";
import "../Marketplace/ILazymint.sol";
import "./IMarketplace.sol";
import "../Rewards/IVaultRewards.sol";
import "../NFT Contracts/IwrapNFT.sol";
import "../Lending/IVaultLenders.sol";
import "../Mortgage/TokenInfo.sol";
import "../Marketplace/IControl.sol";
import "./IMortgageRegister.sol";

contract Mortgages is AccessControl, ReentrancyGuard, IMortgageInterest, IERC721Receiver {
    using SafeERC20 for IERC20;
    ///@dev developer role created

    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    //Change to mainnet multisig-wallet
    address public walletPanoram = 0x105f83C74aD66776e317ABa4AeC1FB392cCa7c37;
    address public mortgageControl;
    address public control;
    address public market;

    // ********* CAMBIAR EL ADDRESS DEL RELAYER BEFORE DEPLOYMENT ********* //

    address public guardian = 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23; //0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // relayer mumbai: 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23;
    TokenInfo public tokenInfo;

    bool private paused;
    uint64 private maxLoan = 8000; //8000 is equal to 80%
    uint64 private minLoan = 1000; //1000 is equal to 10%
    uint64 private mortgageFee = 150; //150 is equal to 1.5%
    uint64 private mintingFee = 150; //150 is equal to 1.5%
    uint256 public mortgageId = 0;
    uint256 private feeLenders = 1800; //Equals 18%
    uint256 private feeRewards = 2200; //Equals 22%
    uint256 private feePanoram = 6000; //Equals 60%
    uint256 public feeBuyMarket = 75; //Equal 0.75%
    uint256 private maxperiod = 24; //60 months is equal to 5 years.
    uint256 private constant MAX_UINT = 2 ** 255;

    IMortgageRegister public mortgageRegister;

    ///@dev address1 collection address
    ///@dev address2 wrapcontract address
    mapping(address => address) private wrapData;

    event mortgageEvent(
        uint256 id, address user, address collection, address wrapContract, uint256 nftId, uint256 loan
    );
    event releaseEvent(uint256 idMortgage, address user, address collection, uint256 nftId, string status);
    event mortgageAgain(uint256 oldId, uint256 newId, address user, uint256 newLoan, uint256 newDebt);
    event seized(uint256 idMortgage, address user, address collection, uint256 nftId, string status);

    constructor(
        address _tokenInfo,
        address _mortgageControl,
        address _market,
        address _token,
        address vaultLenders,
        address vaultRewards,
        address RewardsLenders,
        address _control,
        address _mortgageRegister
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); // cambiar por multisig
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); // cambiar por multisig

        tokenInfo = TokenInfo(_tokenInfo);
        mortgageRegister = IMortgageRegister(_mortgageRegister);
        mortgageControl = _mortgageControl;
        control = _control;
        market = _market;

        permissions(_token, vaultLenders, vaultRewards, RewardsLenders);
        approveToken(_token);
    }

    modifier validToken(address _token) {
        if (!tokenInfo.getToken(_token)) {
            revert("Token not support");
        }
        _;
    }

    modifier onlydev() {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    modifier onlyRelayer() {
        if (guardian != msg.sender) {
            revert("You're not allowed");
        }
        _;
    }

    /// @dev Modifier to check if the contract is paused.
    modifier NotPaused() {
        if (paused) {
            revert("Lending is paused");
        }
        _;
    }

    struct LocalMortgage {
        address _collection;
        uint256 valuation;
        uint256 price;
        uint256 presalePrice;
        uint256 avaibleLoan;
        uint256 downPay;
        address wrapContract;
        uint256 fee;
        uint256 total;
        uint256 total2;
        uint256 total3;
        uint256 pan;
        uint256 rewards;
        uint256 lenders;
        uint256 pan2;
        uint256 rewards2;
        uint256 lenders2;
    }

    struct LocalMortgage2 {
        uint256 amount;
        uint256 tokenId;
        string uri;
        uint256 minLoan;
        address owner;
        bool isPay;
        uint256 marketPrice;
        uint256 buyFee;
        bool mortgageAgain;
        uint256 linkId;
        uint256 subtotal;
        uint256 newLoan;
        uint256 mintfee;
        uint256 debt;
        uint256 maxAvaible;
        uint256 money;
    }

    struct LocalMortgage3 {
        uint256 _loan;
        uint256 _period;
        uint256 length1;
        uint256 length2;
        uint256[] ids;
        uint256[] nfts;
    }

    struct Localdebt {
        uint256 totalDebt;
        uint256 totalMonthlyPay;
        uint256 totalDelayedMonthlyPay;
        uint256 totalToPayOnLiquidation;
        uint256 lastTimePayment;
        bool isMonthlyPaymentPayed;
        bool isMonthlyPaymentDelayed;
        bool liquidate;
        uint256 newDebt;
    }

    struct LocalVaults {
        address vaultLenders;
        address vaultRewards;
        address RewardsLenders;
    }

    function openMortgage(address collection, uint256 loan, uint256 period, address token)
        public
        validToken(token)
        NotPaused
        returns (uint256 id)
    {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        LocalMortgage3 memory locals3;
        LocalVaults memory vaults;

        locals3._loan = loan;
        locals3._period = period;

        locals._collection = collection;
        if (locals._collection == address(0)) {
            revert("is address 0");
        }

        if (period > maxperiod) {
            revert("exceed maximum period");
        }

        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.price = ILazyNFT(locals._collection).getPrice();
        locals.avaibleLoan;
        if (locals.price >= locals.valuation) {
            locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        } else {
            locals.avaibleLoan = _getPortion(locals.price, maxLoan);
        }
        if (locals3._loan > locals.avaibleLoan) {
            revert("exceed your maximum loan");
        }
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if (locals3._loan < locals2.minLoan) {
            revert("Less than allowed");
        }
        locals.downPay = locals.price - locals3._loan;

        id = ++mortgageId;
        locals.wrapContract = wrapData[locals._collection];

        locals.fee = _getPortion(loan, mortgageFee); //mortgage fee calculation
        locals2.mintfee = _getPortion(locals.price, mintingFee); //minting fee calculation

        IERC20(token).safeTransferFrom(msg.sender, address(this), locals.downPay); //transfer downpayment

        (vaults.vaultLenders, vaults.RewardsLenders, vaults.vaultRewards) = tokenInfo.getVaultInfo(token);

        //Distribution fees
        locals2.debt = locals3._loan + locals.fee + locals2.mintfee;
        IVaultLenders(vaults.vaultLenders).withdraw(locals2.debt, token);

        (locals.pan, locals.rewards, locals.lenders) = calcFees(locals.fee);
        (locals.pan2, locals.rewards2, locals.lenders2) = calcFees(locals2.mintfee);
        locals.total2 = locals.rewards + locals.rewards2;
        locals.total3 = locals.lenders + locals.lenders2;

        IVaultRewards(vaults.vaultRewards).deposit(locals.total2, token);
        IVaultRewards(vaults.RewardsLenders).deposit(locals.total3, token);
        locals2.amount = locals.pan + locals.pan2 + locals.price;
        IERC20(token).safeTransfer(walletPanoram, locals2.amount); //transfer percentage fee and NFT cost
        //Create and wrap NFT
        locals2.tokenId =
            INFTMarket(market).mintingMortgage(locals._collection, address(this), msg.sender, locals.price);
        locals2.uri = ILazyNFT(locals._collection).tokenURI(locals2.tokenId);
        IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, locals2.tokenId, locals2.uri);
        ILazyNFT(locals._collection).transferFrom(address(this), locals.wrapContract, locals2.tokenId);
        //Register information
        IMortgageControl(mortgageControl).addMortgageId(locals._collection, locals2.tokenId, id);
        IMortgageControl(mortgageControl).addRegistry(
            id,
            msg.sender,
            locals._collection,
            locals.wrapContract,
            locals2.tokenId,
            locals2.debt,
            locals.downPay,
            locals.price,
            block.timestamp,
            locals3._period
        );
        IMortgageControl(mortgageControl).addIdInfo(id, msg.sender);
        // Changes v2
        mortgageRegister.registerInitialMortgageData(id, msg.sender, locals2.debt);

        IMortgageControl(mortgageControl).updateLastTimePayment(msg.sender, id, block.timestamp);

        emit mortgageEvent(id, msg.sender, locals._collection, locals.wrapContract, locals2.tokenId, locals2.debt);
    }
    /// @param amount The number of mortgages to be applied for
    /// @param loan Array with the amount of each loan requested
    /// @param period Array with duration of each loan requested.
    /// @custom:audit que pasa si envian una address rara o que no es una coleccion

    function batchMortgage(
        address collection,
        uint256 amount,
        uint256[] calldata loan,
        uint256[] calldata period,
        address token
    ) public validToken(token) NotPaused {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        LocalMortgage3 memory locals3;

        locals3.length1 = loan.length;
        locals3.length2 = period.length;
        if (amount != locals3.length1 || amount != locals3.length2) {
            revert("Arrays mismatch");
        }

        for (uint256 i = 0; i < amount;) {
            locals3._loan = loan[i];
            locals3._period = period[i];

            locals._collection = collection;
            if (locals._collection == address(0)) {
                revert("is address 0");
            }

            if (locals3._period > maxperiod) {
                revert("exceed maximum period");
            }

            locals.valuation = ILazyNFT(locals._collection).nftValuation();
            locals.price = ILazyNFT(locals._collection).getPrice();
            //locals.avaibleLoan;
            if (locals.price >= locals.valuation) {
                locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
            } else {
                locals.avaibleLoan = _getPortion(locals.price, maxLoan);
            }
            if (locals3._loan > locals.avaibleLoan) {
                revert("exceed your maximum loan");
            }
            locals2.minLoan = _getPortion(locals.valuation, minLoan);
            if (locals3._loan < locals2.minLoan) {
                revert("Less than allowed");
            }
            locals.downPay = locals.price - locals3._loan;

            uint256 id = ++mortgageId;
            locals.wrapContract = wrapData[locals._collection];

            locals2.debt = calcsDeposits(loan[i], locals.downPay, locals.price, token);

            //Create and wrap NFT
            locals2.tokenId =
                INFTMarket(market).mintingMortgage(locals._collection, address(this), msg.sender, locals.price);
            locals2.uri = ILazyNFT(locals._collection).tokenURI(locals2.tokenId);
            IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, locals2.tokenId, locals2.uri);
            ILazyNFT(locals._collection).transferFrom(address(this), locals.wrapContract, locals2.tokenId);
            //Register information
            IMortgageControl(mortgageControl).addMortgageId(locals._collection, locals2.tokenId, id);
            IMortgageControl(mortgageControl).addRegistry(
                id,
                msg.sender,
                locals._collection,
                locals.wrapContract,
                locals2.tokenId,
                locals2.debt,
                locals.downPay,
                locals.price,
                block.timestamp,
                locals3._period
            );
            IMortgageControl(mortgageControl).addIdInfo(id, msg.sender);
            // Changes v2
            mortgageRegister.registerInitialMortgageData(id, msg.sender, locals2.debt);
            IMortgageControl(mortgageControl).updateLastTimePayment(msg.sender, id, block.timestamp);

            emit mortgageEvent(id, msg.sender, locals._collection, locals.wrapContract, locals2.tokenId, locals2.debt);
            unchecked {
                ++i;
            }
        }
    }

    function calcsDeposits(uint256 loan, uint256 downPay, uint256 _price, address token)
        private
        returns (uint256 debt)
    {
        LocalMortgage memory locals;
        LocalVaults memory vaults;
        uint256 fee = _getPortion(loan, mortgageFee); //mortgage fee calculation
        uint256 mintfee = _getPortion(_price, mintingFee); //minting fee calculation

        IERC20(token).safeTransferFrom(msg.sender, address(this), downPay); //transfer downpayment

        (vaults.vaultLenders, vaults.RewardsLenders, vaults.vaultRewards) = tokenInfo.getVaultInfo(token);

        //Distribution fees
        debt = loan + fee + mintfee;
        IVaultLenders(vaults.vaultLenders).withdraw(debt, token);

        (locals.pan, locals.rewards, locals.lenders) = calcFees(fee);
        (locals.pan2, locals.rewards2, locals.lenders2) = calcFees(mintfee);
        locals.total2 = locals.rewards + locals.rewards2; // lo que se envia al vault rewards BH
        locals.total3 = locals.lenders + locals.lenders2; // lo que se envia a vault lenders rewards

        IVaultRewards(vaults.vaultRewards).deposit(locals.total2, token);
        IVaultRewards(vaults.RewardsLenders).deposit(locals.total3, token);
        uint256 amount = locals.pan + locals.pan2 + _price;
        IERC20(token).safeTransfer(walletPanoram, amount); //transfer percentage fee and NFT cost
    }

    function openPresaleMortgage(address collection, /* , address user */ uint256 loan, uint256 period, address token)
        public
        NotPaused
        returns (uint256 id)
    {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        LocalMortgage3 memory locals3;
        LocalVaults memory vaults;
        locals._collection = collection;
        locals3._loan = loan;
        locals3._period = period;
        if (locals._collection == address(0)) {
            revert("is address 0");
        }
        if (period > maxperiod) {
            revert("exceed maximum period");
        }

        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.presalePrice = ILazyNFT(locals._collection).getPresale();
        locals.avaibleLoan;
        if (locals.presalePrice >= locals.valuation) {
            locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        } else {
            locals.avaibleLoan = _getPortion(locals.presalePrice, maxLoan);
        }
        if (locals3._loan > locals.avaibleLoan) {
            revert("exceed your maximum loan");
        }
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if (locals3._loan < locals2.minLoan) {
            revert("Less than allowed");
        }
        locals.downPay = locals.presalePrice - locals3._loan;

        id = ++mortgageId;
        locals.wrapContract = wrapData[locals._collection];

        locals.fee = _getPortion(locals3._loan, mortgageFee); //mortgage fee calculation
        locals2.mintfee = _getPortion(locals.presalePrice, mintingFee); //minting fee calculation
        IERC20(token).safeTransferFrom(msg.sender, address(this), locals.downPay); //transfer downpayment
        (vaults.vaultLenders, vaults.RewardsLenders, vaults.vaultRewards) = tokenInfo.getVaultInfo(token);
        //Distribution fees
        locals2.debt = locals3._loan + locals.fee + locals2.mintfee;

        IVaultLenders(vaults.vaultLenders).withdraw(locals2.debt, token);

        (locals.pan, locals.rewards, locals.lenders) = calcFees(locals.fee);

        (locals.pan2, locals.rewards2, locals.lenders2) = calcFees(locals2.mintfee);

        //locals.total = locals.pan +locals.pan2;
        locals.total2 = locals.rewards + locals.rewards2;
        locals.total3 = locals.lenders + locals.lenders2;

        IVaultRewards(vaults.vaultRewards).deposit(locals.total2, token);
        IVaultRewards(vaults.RewardsLenders).deposit(locals.total3, token);
        locals2.amount = locals.pan + locals.pan2 + locals.price;
        IERC20(token).safeTransfer(walletPanoram, locals2.amount); //transfer percentage fee and NFT cost
        //Create and wrap NFT
        locals2.tokenId = INFTMarket(market).mintingPresaleMortgage(
            locals._collection, address(this), msg.sender, locals.presalePrice
        );
        locals2.uri = ILazyNFT(collection).tokenURI(locals2.tokenId);
        IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, locals2.tokenId, locals2.uri);
        ILazyNFT(locals._collection).transferFrom(address(this), locals.wrapContract, locals2.tokenId);
        //Register information
        IMortgageControl(mortgageControl).addMortgageId(locals._collection, locals2.tokenId, id);
        IMortgageControl(mortgageControl).addRegistry(
            id,
            msg.sender,
            locals._collection,
            locals.wrapContract,
            locals2.tokenId,
            locals2.debt,
            locals.downPay,
            locals.presalePrice,
            block.timestamp,
            locals3._period
        );
        IMortgageControl(mortgageControl).addIdInfo(id, msg.sender);
        // Changes v2
        mortgageRegister.registerInitialMortgageData(id, msg.sender, locals2.debt);

        IMortgageControl(mortgageControl).updateLastTimePayment(msg.sender, id, block.timestamp);

        emit mortgageEvent(id, msg.sender, locals._collection, locals.wrapContract, locals2.tokenId, locals2.debt);
    }

    function openMarketMortgage(address collection, uint256 nftId, uint256 loan, uint256 period, address token)
        public
        NotPaused
        returns (uint256 id)
    {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        LocalMortgage3 memory locals3;
        LocalVaults memory vaults;
        locals._collection = collection;
        locals3._loan = loan;
        locals3._period = period;
        if (locals._collection == address(0)) {
            revert("is address 0");
        }
        if (period > maxperiod) {
            revert("exceed maximum period");
        }
        locals2.marketPrice = INFTMarket(market).getSalePrice(locals._collection, nftId);
        if (locals2.marketPrice == 0) {
            revert("no sale exists");
        }
        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.avaibleLoan;
        if (locals.presalePrice >= locals.valuation) {
            locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        } else {
            locals.avaibleLoan = _getPortion(locals2.marketPrice, maxLoan);
        }
        if (locals3._loan > locals.avaibleLoan) {
            revert("exceed your maximum loan");
        }
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if (locals3._loan < locals2.minLoan) {
            revert("Less than allowed");
        }
        locals.downPay = locals2.marketPrice - locals3._loan;

        id = ++mortgageId;
        locals.wrapContract = wrapData[locals._collection];

        locals.fee = _getPortion(locals3._loan, mortgageFee); //mortgage fee calculation
        locals2.buyFee = _getPortion(locals2.marketPrice, feeBuyMarket);
        IERC20(token).safeTransferFrom(msg.sender, address(this), locals.downPay); //transfer downpayment
        (vaults.vaultLenders,,) = tokenInfo.getVaultInfo(token);
        //Distribution fees
        locals2.debt = locals3._loan + locals.fee + locals2.buyFee;
        IVaultLenders(vaults.vaultLenders).withdraw(locals2.debt, token);
        payFees(locals.fee, token);

        //Create and wrap NFT
        locals.total = locals2.marketPrice + locals2.buyFee;
        buyNFT(locals._collection, nftId, token, locals.total, locals2.buyFee);
        //INFTMarket(market).makeBid(collection, nftId, token, locals.total, locals2.buyFee); //buy NFT in Market
        locals2.uri = ILazyNFT(locals._collection).tokenURI(nftId);
        IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, nftId, locals2.uri);
        ILazyNFT(locals._collection).transferFrom(address(this), locals.wrapContract, nftId);
        //Register information
        IMortgageControl(mortgageControl).addMortgageId(locals._collection, nftId, id);
        IMortgageControl(mortgageControl).addRegistry(
            id,
            msg.sender,
            locals._collection,
            locals.wrapContract,
            nftId,
            locals2.debt,
            locals.downPay,
            locals2.marketPrice,
            block.timestamp,
            locals3._period
        );
        IMortgageControl(mortgageControl).addIdInfo(id, msg.sender);

        // Changes v2
        mortgageRegister.registerInitialMortgageData(id, msg.sender, locals2.debt);

        IMortgageControl(mortgageControl).updateLastTimePayment(msg.sender, id, block.timestamp);

        emit mortgageEvent(id, msg.sender, locals._collection, locals.wrapContract, nftId, locals2.debt);
    }

    function buyNFT(address _collection, uint256 _nftId, address _token, uint256 _total, uint256 _buyFee) internal {
        INFTMarket(market).makeBid(_collection, _nftId, _token, _total, _buyFee, msg.sender); //buy NFT in Market
    }

    function payFees(uint256 _fee, address token) internal {
        (, address RewardsLenders, address vaultRewards) = tokenInfo.getVaultInfo(token);
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(_fee);
        IVaultRewards(vaultRewards).deposit(rewards, token);
        IVaultRewards(RewardsLenders).deposit(lenders, token);
        IERC20(token).safeTransfer(walletPanoram, pan); //transfer percentage fee
    }

    function mortgagePaid(uint256 idMortgage, address collection, address user, uint256 tokenId) public NotPaused {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        locals._collection = collection;
        locals2.tokenId = tokenId;
        if (locals._collection == address(0)) {
            revert("is address 0");
        }
        locals.wrapContract = wrapData[locals._collection];
        locals2.owner = IwrapNFT(locals.wrapContract).ownerOf(locals2.tokenId);
        if (locals2.owner != msg.sender) {
            revert("not the owner");
        }
        locals2.isPay = IMortgageControl(mortgageControl).getMortgageStatus(user, idMortgage);
        if (!locals2.isPay) {
            revert("active mortgage");
        }
        //burn wrapNFT and transfer the original NFT
        IwrapNFT(locals.wrapContract).unWrap(user, locals2.tokenId);

        IMortgageControl(mortgageControl).eraseMortgageId(collection, tokenId);

        emit releaseEvent(idMortgage, user, locals._collection, locals2.tokenId, "released");
    }

    function getRemortgageInfo(address user, uint256 oldMortgage)
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        Localdebt memory debt;
        if (IMortgageControl(mortgageControl).getIdInfo(oldMortgage) == address(0)) {
            revert("mortgage not exist");
        }

        (locals2.mortgageAgain, locals2.linkId) = IMortgageControl(mortgageControl).mortgageLink(user, oldMortgage);
        if (locals2.mortgageAgain || locals2.linkId != 0) {
            revert("more than 1 re-mortgage");
        }

        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        //check old mortagage
        // Changes v2
        (debt.totalDebt,,, debt.isMonthlyPaymentPayed,) =
            IMortgageControl(mortgageControl).getFrontMortgageData(user, oldMortgage);
        if (!debt.isMonthlyPaymentPayed) {
            revert("payment due");
        }
        //Mortgage calculations
        locals2.maxAvaible = locals.valuation - debt.totalDebt; //Max Loan Avaible
        locals.downPay = locals.valuation - locals.avaibleLoan; //downpayment
        locals2.newLoan = locals2.maxAvaible - locals.downPay; //Amount available for lending

        //New Mortgage
        locals.fee = _getPortion(locals2.newLoan, mortgageFee); //mortgage fee calculation
        //Total debt owed by the customer to Panorama (new loan + what is still owed to Panorama).
        debt.newDebt = (locals.valuation - locals.downPay) + locals.fee;
        return (locals2.maxAvaible, locals.downPay, locals2.newLoan, locals.fee, debt.newDebt);
    }

    function seizeNFT(uint256 idMortgage, address collection, address user, uint256 tokenId)
        public
        NotPaused
        onlyRelayer
    {
        if (collection == address(0)) {
            revert("is address 0");
        }
        bool liquidate = IMortgageControl(mortgageControl).getMortgageLiquidationStatus(user, idMortgage);

        if (!liquidate) {
            revert("up to date");
        }
        address _wrapContract = wrapData[collection];
        IwrapNFT(_wrapContract).unWrap(guardian, tokenId);

        IControl(control).addQuantity(guardian, collection, 1);
        IControl(control).removeQuantity(user, collection, 1);

        emit seized(idMortgage, user, collection, tokenId, "seized");
    }

    function _getPortion(uint256 _valuation, uint256 _percentage) internal pure returns (uint256) {
        return (_valuation * (_percentage)) / 10000;
    }

    function calcFees(uint256 _fee) internal view returns (uint256 panoram, uint256 rewards, uint256 lenders) {
        panoram = _getPortion(_fee, feePanoram);
        rewards = _getPortion(_fee, feeRewards);
        lenders = _getPortion(_fee, feeLenders);
        return (panoram, rewards, lenders);
    }

    function addWrapData(address collection, address wrap) public onlydev {
        wrapData[collection] = wrap;
    }

    function updateMaxPeriod(uint256 _maxPeriod) public onlydev {
        maxperiod = _maxPeriod;
    }

    function updateRelayer(address _relay) public onlydev {
        guardian = _relay;
    }

    function updateMortgageControl(address _newControl) public onlydev {
        mortgageControl = _newControl;
    }

    // Changes v2
    function updateMortgageRegister(address _newMR) external onlydev {
        mortgageRegister = IMortgageRegister(_newMR);
    }

    function updateMarket(address _newMarket) public onlydev {
        market = _newMarket;
    }

    function updateTokenInfo(address _tokenInfo) public onlydev {
        tokenInfo = TokenInfo(_tokenInfo);
    }

    function updateMaxLoan(uint64 _maxLoan) public onlydev {
        maxLoan = _maxLoan;
    }

    function updateMinLoan(uint64 _minLoan) public onlydev {
        minLoan = _minLoan;
    }

    function updateFeeRewards(uint256 _newfeeRewards) public onlydev {
        feeRewards = _newfeeRewards;
    }

    function updateFeePanoram(uint256 _newfeePanoram) public onlydev {
        feePanoram = _newfeePanoram;
    }

    function updateFeeLenders(uint256 _newfeeLenders) public onlydev {
        feeLenders = _newfeeLenders;
    }

    function updateWalletPanoram(address _newWalletPanoram) public onlydev {
        walletPanoram = _newWalletPanoram;
    }

    function updateMortgageID(uint256 _mortgageId) public onlydev {
        mortgageId = _mortgageId;
    }

    function PausedContract(bool _status) public onlydev {
        paused = _status;
    }

    function permissions(address _token, address _lender, address _rewards, address _lendersrewards)
        public
        onlydev
        validToken(_token)
    {
        IERC20(_token).approve(_lender, MAX_UINT);
        IERC20(_token).approve(_rewards, MAX_UINT);
        IERC20(_token).approve(_lendersrewards, MAX_UINT);
    }

    function approveToken(address _token) public onlydev {
        IERC20(_token).approve(market, MAX_UINT); //approve BUSD Testnet
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;
interface INFTMarket{
    function mintingMortgage(address _collection, address _owner, address _user,uint256 _value)  external returns(uint256 _nftId);

    function mintingPresaleMortgage(address _collection, address _owner, address _user,uint256 _value)  external returns(uint256 _nftId);

    function minting(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) external;

    function batchmint(address _collection, address _owner, uint256 _amount ,uint256 _value, uint256 _fee, address _token) external;

    function presaleMint(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) external;

    function presaleMintbatch(address _collection, address _owner, uint256 _amount ,uint256 _value, uint256 _fee, address _token) external;

    function makeBid(address _nftContractAddress, uint256 _tokenId, address _erc20Token, uint256 _tokenAmount, 
    uint256 _feeAmount, address _newOwner) external;

    function getSale(address collection, uint256 id) external view returns
    (uint256 _buyNowPrice,address _nftHighestBidder,address _nftSeller,address _ERC20Token,
    address[] memory _feeRecipients,uint32[] memory _feePercentages);       

    function getSalePrice(address collection, uint256 id) external view returns (uint256 _buyNowPrice);
}

// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

import "./IMortgageInterest.sol";

interface IMortgageControl is IMortgageInterest {
    function addIdInfo(uint256 id, address wallet) external;

    function updateCapitalPay(uint256 id, address wallet, uint256 _newDebt) external;

    function getTotalMortgages() external view returns (uint256);

    function getCapitalPay(address _user, uint256 _mortgageId) external view returns (uint256 _capitalPay);

    function getDebtInfo(address _user, uint256 _mortgageId) external view returns (uint256, uint256, uint256);

    function getMortgageLiquidationStatus(address _user, uint256 _mortgageId) external view returns (bool _status);

    function mortgageLink(address _user, uint256 _mortgageId)
        external
        view
        returns (bool _mortgageAgain, uint256 _linkId);

    function getMortgagesForWallet(address _wallet, address _collection)
        external
        view
        returns (uint256[] memory _idMortgagesForCollection);

    function getuserToMortgageInterest(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (MortgageInterest memory);

    // Get FrontEnd Data
    // Changes v2
    function getFrontMortgageData(address _wallet, uint256 _IdMortage)
        external
        view
        returns (
            uint256 totalDebt,
            uint256 lastTimePayment,
            uint8 strikes,
            bool isMonthlyPaymentDelayed,
            bool liquidate
        );

    function getIdInfo(uint256 id) external view returns (address _user);

    function getInterestRate() external view returns (uint64 _interest);

    function getMortgageId(address _collection, uint256 _nftId) external view returns (uint256 _mortgageId);

    function getStartDate(address _wallet, uint256 _mortgageID) external view returns (uint256);

    function getUserInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (address, uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, bool, bool, uint256);

    function getMortgageStatus(address _user, uint256 _mortgageId) external view returns (bool _status);

    function addMortgageId(address _collection, uint256 _nftId, uint256 _loanId) external;

    function eraseMortgageId(address _collection, uint256 _nftId) external;

    function addRegistry(
        uint256 id,
        address wallet,
        address _collection,
        address _wrapContract,
        uint256 _nftId,
        uint256 _loan,
        uint256 _downPay,
        uint256 _price,
        uint256 _startDate,
        uint256 _period
    ) external;

    function updateMortgageLink(
        uint256 oldId,
        uint256 newId,
        address wallet,
        uint256 _loan,
        uint256 _downPay,
        uint256 _startDate,
        uint256 _period,
        bool _mortageState
    ) external;

    function updateMortgageState(uint256 id, address wallet, bool _state) external;

    function updateMortgagePayment(uint256 id, address wallet) external;

    function resetDebt(address _wallet, uint256 _idMortgage) external;

    function updateTotalDebt(address _wallet, uint256 _idMortgage, uint256 _totalDebt) external;

    function updateLastTimePayment(address _wallet, uint256 _idMortgage, uint256 _lastPayment) external;

    function migrateMortgateInterest(address _wallet, uint256 _IdMortgage, MortgageInterest calldata mort) external;

    function migrateMortgateDebt(address _wallet, uint256 _IdMortgage, Information calldata _debt) external;

    // Changes v2
    function saveMortgageInterestData(
        uint256 _id,
        address _wallet,
        uint256 _DailyInt,
        uint256 _DailyPanoramInt,
        uint256 _DayRewardLenderInt,
        uint256 _DelayedIntDaily,
        uint256 _DelayedIntPanoramDaily,
        uint256 _DelayedIntRewLender
    ) external;

    function resetStrikes(uint256 _id, address _user) external;

    function updateStrikes(uint256 _idMortgage, address _user, uint256 _payPerNFT, address collection)
        external
        returns (bool liquidated, uint256 amountLiquidated);

    function updateMonthlyPaymentDelayed(address _wallet, uint256 _idMortgage, bool _state) external;

    function updateSoldAtAuction(uint256 id, address wallet, bool _state) external;

    function getCollection(address _wallet, uint256 _mortgageID) external view returns (address _collection);

    function reduceDelayedMortgages(address _wallet, address _collection) external;

    function getRetainedRent(address _user, address _collection, uint256 _mortgageID)
        external
        view
        returns (uint256 _userRetainedRents);

    function resetRentRetained(address _user, address _collection, uint256 _mortgageID) external;

    /// @dev Function to set the interest amount paid to Lenders with the retained rents when the user is liquidated.
    function setInterestLendersPaidOnLiquidation(uint256 _idMortgage, address _user, uint256 _amountLenders) external;

    /// @dev Function to set the interest amount paid to Lenders with the retained rents when the user is liquidated.
    function setInterestPanoramPaidOnLiquidation(uint256 _idMortgage, address _user, uint256 _amountPanoram) external;

    /// @dev Function to get the amount of interest paid with the retained rents.
    function getInterestPaid(address _user, uint256 _mortgageID)
        external
        view
        returns (uint256 LendersInterest, uint256 PanoramInterest);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IwrapNFT is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);
 
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function holdInfo(uint256 tokenId) external view returns (uint32);

    function mintInfo(address _owner) external view  returns (uint32);

    function wrapNFT(address _wallet, uint256 _Id, string memory _tokenURI) external;

    function unWrap(address _wallet, uint256 _Id) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TokenInfo is AccessControl {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    
    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23); 
    }

    struct Vaults{
        address lender;
        address lenderRewards;
        address rewards;
    }
    //registration and control of approved tokens
    mapping(address => bool) internal tokens;
    //save the token contract and the vault for it
    mapping(address => Vaults) internal vaultsInfo;
    //save the collection contract and the rental vault contract to be used for each collection
    mapping(address => address) internal collectionToVault;

    function addToken(address _token) public onlydev {
        tokens[_token] = true;
    }

    function removeToken(address _token) public onlydev {
        tokens[_token] = false;
    }

    function getToken(address _token) public view returns(bool _ok){
        return tokens[_token];
    }

    function addVaultRegistry(address _token, address _lender,address _lenderRewards,address _rewards) public onlydev  {
        vaultsInfo[_token].lender = _lender;
        vaultsInfo[_token].lenderRewards = _lenderRewards;
        vaultsInfo[_token].rewards = _rewards;
    }

    function removeVaultRegistry(address _token) public onlydev  {
        vaultsInfo[_token].lender = address(0);
        vaultsInfo[_token].lenderRewards = address(0);
        vaultsInfo[_token].rewards = address(0);
    }

    function getVaultInfo(address _token) public view returns(address _lender, address _lenderRewards,address _rewards){
        return ( vaultsInfo[_token].lender,
        vaultsInfo[_token].lenderRewards,
        vaultsInfo[_token].rewards);
    }

    function addVaultRent(address _collection, address _vault) public onlydev {
        collectionToVault[_collection] = _vault;
    }

    function removeVaultRent(address _collection) public onlydev {
        collectionToVault[_collection] = address(0);
    }

    function getVaultRent(address _collection) public view returns(address _vault){
        return collectionToVault[_collection];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

/// @title Vault Rewards Builder & Holders Interface.
/// @author Panoram Finance.
/// @notice Use this interface in other contracts to connect to the Vault Rewards Builder & Holders Contract.
interface IVaultRewards {

    /// @dev Function to deposit money in the vault.
    function deposit(uint256 _amount,  address _token) external;

    /// @dev Function to withdraw money from the vault.
    function withdraw(uint256 amount, address _token) external;

    /// @dev Function for the Multisig to withdraw all the money from the vault if necessary in an emergency.
    function withdrawAll() external;

    /// @dev Function to read the amount of rewards to distribute each day.
    function seeDaily() external returns (uint256 tempRewards);

    /// @dev Function to get the last time the seeDaily flag was calculated.
    function getLastCall() external view returns(uint256 _last);

    /// @dev Function to get the available rewards in the vault to distribute.
    function getAvaibleRewards() external view returns(uint256 _avaible);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.11;

/// @title Vault Lenders Interface.
/// @author Panoram Finance.
/// @notice You can use this interface to connect to the Vault Lenders contract.
interface IVaultLenders {
    /// @dev Function to deposit tokens in the vault.
    function deposit(uint256,address) external;

    /// @dev Function to deposit Capital payments for loans.
    function depositCapital(uint256,address) external;

    /// @dev Function to withdraw money when a loan is created
    function withdraw(uint256,address) external;

    /// @dev Function for the multisign to withdraw all the money in the vault if necessary.
    function withdrawAll() external;

    /// @dev Function to get the variable totalSupply, that represents the total tokens in the vault.
    function totalSupply() external view returns (uint256);

    /// @dev Function to get the total borrowed money.
    function getBorrows() external view returns(uint256 _borrows);

    /// @dev Function to get the available money for loans.
    function getAvaible() external view returns(uint256 _avaible);

    /// @dev Function to add a withdrawal request for the money that the user deposited in lending. 
    /// @dev They will be able to withdraw the money when the withdrawal waiting time is over.
    function addRequest(uint256 _amount) external;

    /// @dev Function to delete a withdrawals request when the user cancel the request.
    function deleteRequest(uint256 _amount) external;

    /// @dev Function to transfer money from the vault to the lending contract to fulfill a user's withdrawal request.
    function claimRequest(uint256 _amount) external;

    /// @dev Function to get the amount of money requested for withdrawal.
    function getMoneyRequest() external view returns(uint256);

    /// @dev Function to get the maximum amount that can be deposit into the vault.
    function getMaxDeposit() external view returns(uint256);

    /// @dev Function to get the minimum amount that can be deposit into the vault.
    function getMinDeposit() external view returns(uint256);

    /// @dev Function to get the percentage of the vault used in loans, based on scale of 10k.
    function usageRatio() external view returns(uint256 _usage);
}

// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

interface IMortgageRegister {
    function registerInitialMortgageData(uint256 _id, address _user, uint256 _totalDebt) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyNFT is IERC165{
    
    function redeem(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function preSale(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory base);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory, uint256 _length);

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
     
    function getPrice() external view returns (uint256);
    
    function getPresale() external view returns (uint256);

    function getPresaleStatus() external view returns (bool);

    function nftValuation() external view returns (uint256 _nftValuation);

    function getValuation() external view returns (uint256 _valuation);

    function setApprovalForAll(address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IControl {

   function getNFTInfo(address _collection, uint256 _id)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint32
        );

    function getNFTMinted(address _wallet) external view returns (uint256 _minted);

    function getNFTQuantity(address _wallet, address _collection)external view returns (uint256 _quantity);

    function getNFTTotal(address _wallet) external view returns (uint256 _total);

    function addRegistry(address _collection, uint256 _nftId, address _wallet,uint32 _timestamp) external;

    function removeRegistry(address _collection, uint256 _nftId) external;

    function addQuantity(address _wallet,address _collection,uint256 _amount) external;

    function removeQuantity(address _wallet,address _collection, uint256 _amount) external;

    function addMinted(address _wallet,uint256 _amount) external;

    function addCounter() external;

    function seeCounter() external view returns(uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

// Changes v2

pragma solidity 0.8.16;

interface IMortgageInterest {
    struct MortgageInterest {
        uint256 totalDebt; // para guardar lo que adeuda el cliente despues de cada pago
        uint256 capitalDailyPay; // pago de capital diario
        uint256 interestDailyPay; // pago total de intereses diarios.
        uint256 interestPanoramDaily; // intereses diarios a pagar a panoram.
        uint256 interestRewardLender; // intereses diarios a pagar al vault de Rewards Lenders.
        uint256 lateInterestDaily; // pago total de intereses moratorios diarios.
        uint256 lateInterestPanoramDaily; // intereses moratorios diarios a pagar a panoram.
        uint256 lateInterestRewardLender; // intereses moratorios diarios a pagar al vault de Rewards Lenders.
        uint256 lastTimePayment; // guardamos la fecha de su ultimo pago para calcular el siguiente pago desde esta fecha
        uint256 interestLendersPaid; // cantidad pagada con las rentas retenidas de los intereses para lenders, al momento de la liquidacion.
        uint256 interestPanoramPaid; // cantidad pagada con las rentas retenidas de los intereses de Panoram, al momento de la liquidacion.
        uint8 strikes; // cuando sean 2 se pasa a liquidacion. Resetear estas variables cuando se haga el pago
        bool isMonthlyPaymentDelayed; // validar si el pago es moratorio
        bool liquidate; // true si el credito se liquido, se liquida cuando el user tiene 3 meses sin pagar
        bool soldAtAuction; // true cuando la hipoteca se vendio y pago en una Subasta por liquidacion.
    }

    ///@notice structure and mapping that keeps track of mortgage
    struct Information {
        address collection;
        uint256 nftId;
        address wrapContract;
        uint256 loan; // total prestado
        uint256 downPay;
        uint256 capitalPay;
        uint256 price;
        uint256 startDate;
        uint256 period; //months
        uint256 payCounter; //Start in zero
        bool isPay; //default is false
        bool mortgageAgain; //default is false
        uint256 linkId; //link to the new mortgage
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}