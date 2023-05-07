// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Modifiers } from "../../libs/LibAppStorage.sol";

contract TestFacet is Modifiers {

    function executeTest(
    )   external
        view
        returns (address)
    {
        return s.feeCollector;
    }
}