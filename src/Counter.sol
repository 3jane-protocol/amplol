// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YieldBearingRebaseToken is ERC20 {
    AggregatorV3Interface internal tvlFeed;
    uint256 private lastRecordedTVL;

    constructor(address _tvlFeed) ERC20("YieldBearingRebaseToken", "YRT") {
        tvlFeed = AggregatorV3Interface(_tvlFeed);
        lastRecordedTVL = getCurrentTVL();
        _mint(msg.sender, 1000 * 10**18); // Initial supply of tokens
    }

    function rebase() public {
        uint256 currentTVL = getCurrentTVL();
        if (currentTVL != lastRecordedTVL) {
            uint256 totalSupply = totalSupply();
            uint256 newSupply = totalSupply * currentTVL / lastRecordedTVL;
            _rebase(newSupply);
            lastRecordedTVL = currentTVL; // Update the last recorded TVL
        }
    }

    function _rebase(uint256 newSupply) internal {
        uint256 currentSupply = totalSupply();
        if (newSupply > currentSupply) {
            _mint(address(this), newSupply - currentSupply);
        } else if (newSupply < currentSupply) {
            _burn(address(this), currentSupply - newSupply);
        }
    }

    function getCurrentTVL() public view returns (uint256) {
        (,int tvl,,,) = tvlFeed.latestRoundData();
        return uint256(tvl);
    }
}
