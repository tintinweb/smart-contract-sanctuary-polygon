// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;
//
//
//                       ██████╗ ████████╗████████╗ ██████╗ ██████╗ ██╗ █████╗
//                      ██╔═══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
//                      ██║   ██║   ██║      ██║   ██║   ██║██████╔╝██║███████║
//                      ██║   ██║   ██║      ██║   ██║   ██║██╔═══╝ ██║██╔══██║
//                      ╚██████╔╝   ██║      ██║   ╚██████╔╝██║     ██║██║  ██║
//                       ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
//
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔═══════⠳⠳ ⠳⠳═══════╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣀⢤⠲⣃⠪⠠⠡⡁  ⡂⡵⡲⡤⣀⠀⠀⠀╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⡔⡍╔═════⠳⠳ ⠳⠳═════╗⢹⢹╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣫⣫╔╝⢔⢔⢔⣨⣴⣷⣽⣖⣯⢷⣮⣐⠡⠡╚╗⡓⣷╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⢮⠞╔╝⣼⣼⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⣷⢜⢔╚╗⠱⡲╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣚⡦╔╝⣿⣿⢯⠀⣿⣿⣷⣿⣿⣿⣾⣷⣷⠀⠀⢿⣗⡌╚╗⢜⡞╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⢎⢷╔╝⣿⠀⠀⣿⢿⣻⠀⠀⠀⠀⠀⢽⣻⢿⣷⠀⠀⡽⣿⡌╚╗⠨⡀╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔═════╗⠀⠀⣿⣻⣻⠀⠀⠀⠀⠀⠀⠀⠀⡳⣝⢿⣿⠀⠀⣳╔═════╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀║█████║⠀⣿⠀⠀⣿⣟⣗⣿⣾⣿⣾⣾⣷⠀⠀⣳⣻⣷⣳⠀║█████║⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⡯⡯⠀⡻⣮⠀⠀⠀⠀⠀⠀⠀⢿⣧⠀⡽⣿⣽⣽⠀⡖|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⢯⡫⠀⡽⠀⢽⣿⡿⣿⣿⣿⠀⠀⢿⣽⠀⣻⣷⣷⠀⡝|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⡳⠀⢮⠀⡯⣿⣟⣿⣿⣿⣿⣿⠀⢽⣯⠀⣻⣿⣿⠀⢕|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⣝⠀⠀⡿⣽⣿⠀⠀⠀⠀⣿⣿⠀⣯⣿⠀⣿⣟⠀⠀⡃|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣟⢮⠀⠀⣯⢿⣯⠀⣿⣿⠀⣿⣿⠀⣾⡷⠀⣿⣯⠀⠀⡅|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⡗⣷⠀⠀⡯⣿⡿⠀⣽⣿⠀⠀⣳⣯⣿⠀⣾⣿⣺⠀⡺⢌|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀|█|█|⡹⣾⠀⠀⣿⢽⣿⣻⠀⣟⣿⡾⣿⢿⠀⣽⣿⣗⠀⠀⣝⠆|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⣀⠀⠀⠀|█|█|⣫⣿⣷⠀⠀⣯⣿⣿⣽⠀⠀⠀⠀⠀⣿⡿⣗⠀⠀⡳⣵⡣|█|█|⢀⠣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡱⡱⡀⡄⠀|█|█|⣽⣾⣿⣟⠀⠀⣞⡿⣿⣷⣯⣿⣾⡿⡯⣯⠀⠀⣿⣿⣽⡗|█|█|⡐⢡⠅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠠⣳⡱⠳⡡⡓⡕⠕⠀|█|█|⣺⣿⣿⣿⣽⠀⠀⡯⡯⡻⡽⡯⡳⡽⣝⠀⠀⣻⣿⣿⣿⡣|█|█|⠢⢃⠂⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡢⢄⠀⡀⠀⠑⢭⢳⢄⢺⢜⠬⠀|█|█|⢾⣿⣷⣿⣷⣯⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⣿⣿⣟⣟⣷⠡|█|█|⠂⢄⠠⢂⢂⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠠⠁⠄⠨⡚⡪⢪⢳⠘⠌⢎⠀|█|█|⣺⣿⣿⣽⢿⣿⣳⣝⠀⠀⠀⠀⠀⠀⢿⣟⡯⣗⣗⣗⢷⡹|█|█|⠡⡂⡅⠎⡔⠖⠨⡣⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡀⠀⠀⠀⠀⠀⠐⠈⠐⠄⢂⠪⠘⡒⡀⡑║███████████████████████████████████║⢐⡡⡑⡺⡱⠹⡪⠉⠁⡈⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠠⠁⠀⡀⡢⢄⠀⠀⠈⠠⠁⠂⢌⠠⠐⠀⠀///⡪ ╔════════════════════════════╗⣐\\\⠠⢉⠙⡌⠊⢀⠠⠐⠀⠀⠀⠠⢊⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⠢⢑⡁⠀⠄⠈⡈⡈⢐⠐⠈⠂///⡗⡱ ║████████████████████████████║⡂⢻\\\⠀⠀⡀⠀⢀⡀⠀⠀⠀⠂⠀⠂⠀⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⡀⠐⢀⠀⠀⢀⠂⠁⢄⡐⠐⠈⠠⠨⡁///⢮ ╔════════════════════════════════╗⠳\\\⠢⠀⠂⡀⠠⠁⠀⠁⠐⠐⠀⠈⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⡐⢔⠝⠀⡄⠄⠀⠨⠀⠁⠂⠐⡈⠀⠅///⠇⡐ ║████████████████████████████████║⢀⠹\\\⠠⡂⠐⠀⠡⠈⠀⡀⠀⠀⠄⠀⠠⢈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢐⠠⠁⠄⠀⠈⠠⠀⠂⠀⢈⢄///⠄ ╔════════════════════════════════════╗⠀\\\⡌⢆⠀⡀⠀⠁⠈⠐⡀⢀⢈⠀⠐⠀⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⢀⢀⠀⠀⠠⠨⡊///⠌⠄ ║████████████████████████████████████║⠀⠁\\\⠈⢎⠢⢈⠀⠀⠁⠀⠁⠀⠂⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀══════════════════════════════════════════════════════════════⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//                      ʕ•̫͡•ʕ•̫͡•ʔ•̫͡•ʔ•̫͡•ʕ•̫͡•ʔ  \\OtterClam//  ʕ•̫͡•ʕ•̫͡•ʔ•̫͡•ʔ•̫͡•ʕ•̫͡•ʔ
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
import './OttoStorage.sol';
import {LibDiamond} from './libraries/LibDiamond.sol';
import {IDiamondCut} from './interfaces/IDiamondCut.sol';
import {IDiamondLoupe} from './interfaces/IDiamondLoupe.sol';

contract OttoV4 is OttoStorage, IDiamondCut, IDiamondLoupe {
    // Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
    // The loupe functions are required by the EIP2535 Diamonds standard
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override onlyAdmin {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facets_ = new Facet[](selectorCount);
        // create an array for counting the number of selectors for each facet
        uint8[] memory numFacetSelectors = new uint8[](selectorCount);
        // total number of facets
        uint256 numFacets;
        // loop through function selectors
        for (
            uint256 selectorIndex;
            selectorIndex < selectorCount;
            selectorIndex++
        ) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            bool continueLoop = false;
            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[
                        numFacetSelectors[facetIndex]
                    ] = selector;
                    // probably will never have more than 256 functions from one facet contract
                    require(numFacetSelectors[facetIndex] < 255);
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory _facetFunctionSelectors)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through function selectors
        for (
            uint256 selectorIndex;
            selectorIndex < selectorCount;
            selectorIndex++
        ) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through function selectors
        for (
            uint256 selectorIndex;
            selectorIndex < selectorCount;
            selectorIndex++
        ) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            bool continueLoop = false;
            // see if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds
            .facetAddressAndSelectorPosition[_functionSelector]
            .facetAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IDiamondCut).interfaceId ||
            interfaceId == type(IDiamondLoupe).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds
            .facetAddressAndSelectorPosition[msg.sig]
            .facetAddress;
        require(facet != address(0), 'Diamond: Function does not exist');
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;
//
//
//                       ██████╗ ████████╗████████╗ ██████╗ ██████╗ ██╗ █████╗
//                      ██╔═══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
//                      ██║   ██║   ██║      ██║   ██║   ██║██████╔╝██║███████║
//                      ██║   ██║   ██║      ██║   ██║   ██║██╔═══╝ ██║██╔══██║
//                      ╚██████╔╝   ██║      ██║   ╚██████╔╝██║     ██║██║  ██║
//                       ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
//
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔═══════⠳⠳ ⠳⠳═══════╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣀⢤⠲⣃⠪⠠⠡⡁  ⡂⡵⡲⡤⣀⠀⠀⠀╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⡔⡍╔═════⠳⠳ ⠳⠳═════╗⢹⢹╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣫⣫╔╝⢔⢔⢔⣨⣴⣷⣽⣖⣯⢷⣮⣐⠡⠡╚╗⡓⣷╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⢮⠞╔╝⣼⣼⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⣷⢜⢔╚╗⠱⡲╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣚⡦╔╝⣿⣿⢯⠀⣿⣿⣷⣿⣿⣿⣾⣷⣷⠀⠀⢿⣗⡌╚╗⢜⡞╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⢎⢷╔╝⣿⠀⠀⣿⢿⣻⠀⠀⠀⠀⠀⢽⣻⢿⣷⠀⠀⡽⣿⡌╚╗⠨⡀╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔═════╗⠀⠀⣿⣻⣻⠀⠀⠀⠀⠀⠀⠀⠀⡳⣝⢿⣿⠀⠀⣳╔═════╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀║█████║⠀⣿⠀⠀⣿⣟⣗⣿⣾⣿⣾⣾⣷⠀⠀⣳⣻⣷⣳⠀║█████║⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⡯⡯⠀⡻⣮⠀⠀⠀⠀⠀⠀⠀⢿⣧⠀⡽⣿⣽⣽⠀⡖|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⢯⡫⠀⡽⠀⢽⣿⡿⣿⣿⣿⠀⠀⢿⣽⠀⣻⣷⣷⠀⡝|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⡳⠀⢮⠀⡯⣿⣟⣿⣿⣿⣿⣿⠀⢽⣯⠀⣻⣿⣿⠀⢕|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⣝⠀⠀⡿⣽⣿⠀⠀⠀⠀⣿⣿⠀⣯⣿⠀⣿⣟⠀⠀⡃|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣟⢮⠀⠀⣯⢿⣯⠀⣿⣿⠀⣿⣿⠀⣾⡷⠀⣿⣯⠀⠀⡅|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⡗⣷⠀⠀⡯⣿⡿⠀⣽⣿⠀⠀⣳⣯⣿⠀⣾⣿⣺⠀⡺⢌|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀|█|█|⡹⣾⠀⠀⣿⢽⣿⣻⠀⣟⣿⡾⣿⢿⠀⣽⣿⣗⠀⠀⣝⠆|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⣀⠀⠀⠀|█|█|⣫⣿⣷⠀⠀⣯⣿⣿⣽⠀⠀⠀⠀⠀⣿⡿⣗⠀⠀⡳⣵⡣|█|█|⢀⠣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡱⡱⡀⡄⠀|█|█|⣽⣾⣿⣟⠀⠀⣞⡿⣿⣷⣯⣿⣾⡿⡯⣯⠀⠀⣿⣿⣽⡗|█|█|⡐⢡⠅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠠⣳⡱⠳⡡⡓⡕⠕⠀|█|█|⣺⣿⣿⣿⣽⠀⠀⡯⡯⡻⡽⡯⡳⡽⣝⠀⠀⣻⣿⣿⣿⡣|█|█|⠢⢃⠂⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡢⢄⠀⡀⠀⠑⢭⢳⢄⢺⢜⠬⠀|█|█|⢾⣿⣷⣿⣷⣯⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⣿⣿⣟⣟⣷⠡|█|█|⠂⢄⠠⢂⢂⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠠⠁⠄⠨⡚⡪⢪⢳⠘⠌⢎⠀|█|█|⣺⣿⣿⣽⢿⣿⣳⣝⠀⠀⠀⠀⠀⠀⢿⣟⡯⣗⣗⣗⢷⡹|█|█|⠡⡂⡅⠎⡔⠖⠨⡣⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡀⠀⠀⠀⠀⠀⠐⠈⠐⠄⢂⠪⠘⡒⡀⡑║███████████████████████████████████║⢐⡡⡑⡺⡱⠹⡪⠉⠁⡈⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠠⠁⠀⡀⡢⢄⠀⠀⠈⠠⠁⠂⢌⠠⠐⠀⠀///⡪ ╔════════════════════════════╗⣐\\\⠠⢉⠙⡌⠊⢀⠠⠐⠀⠀⠀⠠⢊⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⠢⢑⡁⠀⠄⠈⡈⡈⢐⠐⠈⠂///⡗⡱ ║████████████████████████████║⡂⢻\\\⠀⠀⡀⠀⢀⡀⠀⠀⠀⠂⠀⠂⠀⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⡀⠐⢀⠀⠀⢀⠂⠁⢄⡐⠐⠈⠠⠨⡁///⢮ ╔════════════════════════════════╗⠳\\\⠢⠀⠂⡀⠠⠁⠀⠁⠐⠐⠀⠈⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⡐⢔⠝⠀⡄⠄⠀⠨⠀⠁⠂⠐⡈⠀⠅///⠇⡐ ║████████████████████████████████║⢀⠹\\\⠠⡂⠐⠀⠡⠈⠀⡀⠀⠀⠄⠀⠠⢈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢐⠠⠁⠄⠀⠈⠠⠀⠂⠀⢈⢄///⠄ ╔════════════════════════════════════╗⠀\\\⡌⢆⠀⡀⠀⠁⠈⠐⡀⢀⢈⠀⠐⠀⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⢀⢀⠀⠀⠠⠨⡊///⠌⠄ ║████████████████████████████████████║⠀⠁\\\⠈⢎⠢⢈⠀⠀⠁⠀⠁⠀⠂⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀══════════════════════════════════════════════════════════════⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//                      ʕ•̫͡•ʕ•̫͡•ʔ•̫͡•ʔ•̫͡•ʕ•̫͡•ʔ  \\OtterClam//  ʕ•̫͡•ʕ•̫͡•ʔ•̫͡•ʔ•̫͡•ʕ•̫͡•ʔ
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
import '../interfaces/IOtto.sol';
import '../interfaces/IOttoItem.sol';
import '../interfaces/IERC1155.sol';
import '../libraries/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol';

interface IOttoItemERC1155 is IOttoItem, IERC1155 {}

contract OttoStorage is
    ERC721AUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    bytes32 public constant ITEM_MANAGER_ROLE = keccak256('ITEM_MANAGER_ROLE');
    uint32 public constant LEVEL_UP_ATTRITUBE_POINTS = 2;

    struct OttoInfo {
        uint256 mintAt;
        uint256 canOpenAt;
        uint256 summonAt;
        uint256 birthday;
        // u16 [
        // Background, SkinColor, SkinType, Clothes, Mouth, Eyes, FacialAccessories,
        // Headwear, Holding, Heraldry, Voice, Personality, Gender, ...
        // ]
        uint256 traits;
        PortalStatus portalStatus;
        bool legendary;
        uint32 attributePoints;
        uint32 ap;
        uint32 exp;
        uint32 level;
        uint256 lastLevelUpAt;
    }

    struct OwnedInfo {
        bool[16] equipped;
        uint256[16] itemId;
    }

    event BaseURIChanged(address indexed sender_, string baseURI_);

    event OpenPortal(
        address indexed sender_,
        uint256 indexed tokenId_,
        bool legendary_
    );

    event SummonOtto(
        address indexed sender_,
        uint256 indexed tokenId_,
        bool legendary_
    );

    event TraitsChanged(uint256 indexed tokenId_, uint16[16] arr_);

    event ItemEquipped(uint256 indexed ottoId_, uint256 indexed itemId_);

    event ItemTookOff(uint256 indexed ottoId_, uint256 indexed itemId_);

    event ItemUsed(uint256 indexed ottoId_, uint256 indexed itemId_);

    event BaseAttributesChanged(uint256 indexed ottoId_, int16[8] attrs_);

    event BaseAttributesUpdated(uint256 indexed ottoId_, int16[8] delta_);

    event EpochBoostsChanged(
        uint256 indexed ottoId_,
        uint32 indexed epoch_,
        int16[9] attrs_
    );

    event EpochBoostsUpdated(
        uint256 indexed ottoId_,
        uint32 indexed epoch_,
        int16[8] delta_
    );

    event ExpIncreased(uint256 indexed ottoId_, uint32 total_, uint32 inc_);

    event LevelUp(
        uint256 indexed ottoId_,
        uint32 fromLv_,
        uint32 toLv_,
        uint32 fromExp_,
        uint32 toExp_,
        uint32 attributePoints_
    );

    event ApIncreased(uint256 indexed ottoId_, uint32 total_, uint32 inc_);

    string internal _baseTokenURI;
    mapping(uint256 => OttoInfo) public infos;
    mapping(uint256 => uint256[]) public candidates;
    uint256 public openPeriod;
    uint256 public decayTarget;
    IOttoItemERC1155 public ITEM;
    mapping(uint256 => OwnedInfo) internal _ownedItems;
    // ottoId -> STR, DEF, DEX, INT, LUK, CON, CUTE, BRS
    mapping(uint256 => int16[8]) internal _baseAttributes;
    // ottoId -> epoch -> STR, DEF, DEX, INT, LUK, CON, CUTE, BRS, HELLDICE
    mapping(uint256 => mapping(uint32 => int16[9])) public epochBoosts;
    // tx -> boosted
    mapping(bytes => bool) internal boosted;

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, _msgSender());
        _;
    }

    modifier onlyManager() {
        _checkRole(MANAGER_ROLE, _msgSender());
        _;
    }

    modifier onlyOttoOwner(uint256 tokenId_) {
        require(_msgSender() == ownerOf(tokenId_), 'NO');
        _;
    }

    modifier onlyOttoOwnerOrItemManager(uint256 tokenId_) {
        require(
            _msgSender() == ownerOf(tokenId_) ||
                hasRole(ITEM_MANAGER_ROLE, _msgSender()),
            'NO'
        );
        _;
    }

    modifier validOttoId(uint256 tokenId_) {
        require(_exists(tokenId_), 'IO');
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IOttoDiamond).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function grantMinter(address minter_) external onlyAdmin {
        _setupRole(MINTER_ROLE, minter_);
    }

    function revokeMinter(address minter_) external onlyAdmin {
        _revokeRole(MINTER_ROLE, minter_);
    }

    function grantManager(address manager_) external onlyAdmin {
        _setupRole(MANAGER_ROLE, manager_);
    }

    function revokeManager(address manager_) external onlyAdmin {
        _revokeRole(MANAGER_ROLE, manager_);
    }

    function rawTraitsOf(uint256 tokenId_)
        public
        view
        validOttoId(tokenId_)
        returns (uint16[16] memory arr_)
    {
        uint256 traits_ = infos[tokenId_].traits;
        for (uint16 i = 0; i < 16; i++) {
            arr_[i] = uint16(traits_ >> (i * 16));
        }
    }

    function traitsOf(uint256 tokenId_)
        public
        view
        validOttoId(tokenId_)
        returns (uint16[16] memory)
    {
        OwnedInfo storage owned = _ownedItems[tokenId_];
        uint16[16] memory arr_ = rawTraitsOf(tokenId_);
        for (uint16 i = 0; i < 16; i++) {
            if (owned.equipped[i]) {
                (, uint16 code_) = ITEM.decode(owned.itemId[i]);
                arr_[i] = code_;
            }
        }
        return arr_;
    }

    function portalStatusOf(uint256 tokenId_)
        public
        view
        validOttoId(tokenId_)
        returns (PortalStatus)
    {
        return infos[tokenId_].portalStatus;
    }

    function genderOf(uint256 tokenId_) public view returns (Gender) {
        return Gender(rawTraitsOf(tokenId_)[12]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from '../interfaces/IDiamondCut.sol';

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256('diamond.standard.diamond.storage');

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert('LibDiamondCut: Incorrect FacetCutAction');
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            'LibDiamondCut: No selectors in facet to cut'
        );
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        enforceHasContractCode(
            _facetAddress,
            'LibDiamondCut: Add facet has no code'
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetAddressAndSelectorPosition[
                    selector
                ] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            'LibDiamondCut: No selectors in facet to cut'
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Replace facet can't be address(0)"
        );
        enforceHasContractCode(
            _facetAddress,
            'LibDiamondCut: Replace facet has no code'
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddress != address(this),
                "LibDiamondCut: Can't replace immutable function"
            );
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            require(
                oldFacetAddress != address(0),
                "LibDiamondCut: Can't replace function that doesn't exist"
            );
            // replace old facet address
            ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress = _facetAddress;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            'LibDiamondCut: No selectors in facet to cut'
        );
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(
            _facetAddress == address(0),
            'LibDiamondCut: Remove facet address must be address(0)'
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition
                memory oldFacetAddressAndSelectorPosition = ds
                    .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress !=
                    address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (
                oldFacetAddressAndSelectorPosition.selectorPosition !=
                selectorCount
            ) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[
                    oldFacetAddressAndSelectorPosition.selectorPosition
                ] = lastSelector;
                ds
                    .facetAddressAndSelectorPosition[lastSelector]
                    .selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                'LibDiamondCut: _init is address(0) but_calldata is not empty'
            );
        } else {
            require(
                _calldata.length > 0,
                'LibDiamondCut: _calldata is empty but _init is not address(0)'
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    'LibDiamondCut: _init address has no code'
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert('LibDiamondCut: _init function reverted');
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '../interfaces/IERC721.sol';

interface IOtto {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);
}

interface IOttoV2 is IOtto {
    event BaseURIChanged(address indexed sender_, string baseURI_);

    event OpenPortal(
        address indexed sender_,
        uint256 indexed tokenId_,
        bool legendary_
    );

    event SummonOtto(
        address indexed sender_,
        uint256 indexed tokenId_,
        bool legendary_
    );

    event TraitsChanged(uint256 indexed tokenId_, uint16[16] arr_);

    function exists(uint256 tokenId_) external view returns (bool);

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external;

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external;

    function portalStatusOf(uint256 tokenId_)
        external
        view
        returns (PortalStatus);

    function legendary(uint256 tokenId_) external view returns (bool);

    function candidatesOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory);

    function traitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function canOpenAt(uint256 tokenId_) external view returns (uint256);
}

// legecy, don't add new functions here
interface IOttoV3 is IOttoV2 {
    event ItemEquipped(uint256 indexed ottoId_, uint256 indexed itemId_);

    event ItemTookOff(uint256 indexed ottoId_, uint256 indexed itemId_);

    event ItemUsed(uint256 indexed ottoId_, uint256 indexed itemId_);

    event BaseAttributesChanged(uint256 indexed ottoId_, int16[8] attrs_);

    event BaseAttributesUpdated(uint256 indexed ottoId_, int16[8] delta_);

    event EpochBoostsChanged(
        uint256 indexed ottoId_,
        uint32 indexed epoch_,
        int16[9] attrs_
    );

    event EpochBoostsUpdated(
        uint256 indexed ottoId_,
        uint32 indexed epoch_,
        int16[8] delta_
    );

    function numericTraitsOf(uint256 tokenId_) external view returns (uint256);

    function ownedItemsOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory itemIds_);

    function baseAttributesOf(uint256 tokenId_)
        external
        view
        returns (int16[8] memory);

    function toNumericTraits(uint16[16] memory arr_)
        external
        pure
        returns (uint256);

    function rawTraitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function genderOf(uint256 tokenId_) external view returns (Gender);

    function equipable(uint256 ottoId_, uint256 itemId_)
        external
        view
        returns (bool);

    function setTraitCode(
        uint256 tokenId_,
        uint8 slot_,
        uint16 code_
    ) external;

    /// @notice Transfer child token from top-down composable to address.
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function updateBaseAttributes(uint256 ottoId_, int16[8] memory delta_)
        external;
}

enum PortalStatus {
    UNOPENED,
    OPENED,
    SUMMONED
}

enum Gender {
    OTTO,
    LOTTIE,
    CLEO
}

interface IOttoLegacyFacet {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);

    function numericTraitsOf(uint256 tokenId_) external view returns (uint256);

    function exists(uint256 tokenId_) external view returns (bool);

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external;

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external;

    function portalStatusOf(uint256 tokenId_)
        external
        view
        returns (PortalStatus);

    function legendary(uint256 tokenId_) external view returns (bool);

    function candidatesOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory);

    function traitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function canOpenAt(uint256 tokenId_) external view returns (uint256);

    function baseAttributesOf(uint256 tokenId_)
        external
        view
        returns (int16[8] memory);

    function toNumericTraits(uint16[16] memory arr_)
        external
        pure
        returns (uint256);

    function rawTraitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function genderOf(uint256 tokenId_) external view returns (Gender);

    function setTraitCode(
        uint256 tokenId_,
        uint8 slot_,
        uint16 code_
    ) external;

    function updateBaseAttributes(uint256 ottoId_, int16[8] memory delta_)
        external;
}

enum ItemActionType {
    EQUIP,
    USE,
    TAKEOFF,
    EQUIP_FROM_OTTO
}

interface IOttoWearingFacet {
    struct ItemActionInput {
        ItemActionType typ;
        uint256 itemId;
        uint256 fromOttoId;
    }
    struct ItemActionOutput {
        bool returned;
        uint256 returnedItemId;
    }

    function equipWillReturn(uint256 ottoId_, uint256 itemId_)
        external
        view
        returns (uint256, bool);

    function equipable(uint256 ottoId_, uint256 itemId_)
        external
        view
        returns (bool);

    function ownedItemsOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory itemIds_);

    /// @notice Transfer child token from top-down composable to address.
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function transferChildToParent(
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external;

    function doItemBatchActions(
        uint256 ottoId_,
        ItemActionInput[] calldata inputs_
    ) external returns (ItemActionOutput[] memory outputs_);
}

interface IOttoAttributeFacet {
    function increaseExp(uint256 ottoId_, uint32 inc_) external;

    function increaseAp(uint256 ottoId_, uint32 inc_) external;

    function useAttributePoints(uint256 ottoId_, int16[7] calldata values_)
        external;

    function nextLevelExp(uint32 n) external pure returns (uint32);

    function totalLevelExp(uint32 n) external pure returns (uint32);

    function calcExp(
        uint32 fromLv_,
        uint32 fromExp_,
        uint32 inc_
    ) external pure returns (uint32 lv_, uint32 exp_);
}

interface IOttoDiamond is
    IOttoLegacyFacet,
    IOttoWearingFacet,
    IOttoAttributeFacet
{}

interface IOttoDiamondERC721 is IOttoDiamond, IERC721 {}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IOttoItem {
    event TransferToParent(
        address indexed _toContract,
        uint256 indexed _toTokenId,
        uint256 _tokenId
    );

    /// @dev This emits when a token is transferred from an ERC721 token
    /// @param _fromContract The contract the token is transferred from
    /// @param _fromTokenId The token the token is transferred from
    /// @param _tokenId The token that is transferred
    event TransferFromParent(
        address indexed _fromContract,
        uint256 indexed _fromTokenId,
        uint256 _tokenId
    );

    /// @notice Transfer token from owner address to a token
    function transferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    function transferFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    function transferAsChild(
        address _fromContract,
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    function encode(uint8 slot_, uint16 code_) external pure returns (uint256);

    function decode(uint256 id_) external pure returns (uint8, uint16);

    function consumable(uint256 tokenId_) external pure returns (bool);

    function wearable(uint256 tokenId_) external pure returns (bool);

    function effect(uint256 tokenId_) external view returns (address);

    function applicable(uint256 itemId_, uint256 ottoId_)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

interface IERC1155Preset is IERC1155MetadataURI {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721AUpgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    IERC721EnumerableUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 private currentIndex;

    uint256 internal collectionSize;
    uint256 internal maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     * `collectionSize_` refers to how many tokens are in the collection.
     */
    function __ERC721A_init(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) internal onlyInitializing {
        require(
            collectionSize_ > 0,
            'ERC721AUpgradeable: collection must have a nonzero supply'
        );
        require(
            maxBatchSize_ > 0,
            'ERC721AUpgradeable: max batch size must be nonzero'
        );
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
        currentIndex = 0;
        nextOwnerToExplicitlySet = 0;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            'ERC721AUpgradeable: global index out of bounds'
        );
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            'ERC721AUpgradeable: owner index out of bounds'
        );
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert('ERC721AUpgradeable: unable to get token of owner by index');
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            'ERC721AUpgradeable: balance query for the zero address'
        );
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(
            owner != address(0),
            'ERC721AUpgradeable: number minted query for the zero address'
        );
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        require(
            _exists(tokenId),
            'ERC721AUpgradeable: owner query for nonexistent token'
        );

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert('ERC721AUpgradeable: unable to determine the owner of token');
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721AUpgradeable.ownerOf(tokenId);
        require(to != owner, 'ERC721AUpgradeable: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721AUpgradeable: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            'ERC721AUpgradeable: approved query for nonexistent token'
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(
            operator != _msgSender(),
            'ERC721AUpgradeable: approve to caller'
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721AUpgradeable: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - there must be `quantity` tokens remaining unminted in the total collection.
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        require(
            to != address(0),
            'ERC721AUpgradeable: mint to the zero address'
        );
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(
            !_exists(startTokenId),
            'ERC721AUpgradeable: token already minted'
        );
        require(
            quantity <= maxBatchSize,
            'ERC721AUpgradeable: quantity to mint too high'
        );
        require(
            totalSupply() + quantity <= collectionSize,
            'ERC721AUpgradeable: out of stock'
        );

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                'ERC721AUpgradeable: transfer to non ERC721Receiver implementer'
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(
            isApprovedOrOwner,
            'ERC721AUpgradeable: transfer caller is not owner nor approved'
        );

        require(
            prevOwnership.addr == from,
            'ERC721AUpgradeable: transfer from incorrect owner'
        );
        require(
            to != address(0),
            'ERC721AUpgradeable: transfer to the zero address'
        );

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(
                    prevOwnership.addr,
                    prevOwnership.startTimestamp
                );
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, 'quantity must be nonzero');
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > collectionSize - 1) {
            endIndex = collectionSize - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), 'not enough minted yet for this cleanup');
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(
                    ownership.addr,
                    ownership.startTimestamp
                );
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
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
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        'ERC721AUpgradeable: transfer to non ERC721Receiver implementer'
                    );
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function burn(uint256 tokenId) external;

    function mint(address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
interface IERC165Upgradeable {
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
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}