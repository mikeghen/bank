pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import '../node_modules/usingtellor/contracts/UsingTellor.sol';


contract BankStorage{
  /*Variables*/
  struct Reserve {
    uint256 collateralBalance;
    uint256 debtBalance;
    uint256 interestRate;
    uint256 originationFee;
    uint256 collateralizationRatio;
    uint256 liquidationPenalty;
    address oracleContract;
    uint256 period;
  }

  struct Token {
    address tokenAddress;
    uint256 price;
    uint256 priceGranularity;
    uint256 tellorRequestId;
    uint256 reserveBalance;
  }

  struct Vault {
    uint256 collateralAmount;
    uint256 debtAmount;
    uint256 createdAt;
  }

  mapping (address => Vault) public vaults;
  Token debt;
  Token collateral;
  Reserve reserve;


  /**
  * @dev Getter function for the current interest rate
  * @return interest rate
  */
  function getInterestRate() public view returns (uint256) {
    return reserve.interestRate;
  }

  /**
  * @dev Getter function for the origination fee
  * @return origination fee
  */
  function getOriginationFee() public view returns (uint256) {
    return reserve.originationFee;
  }

  /**
  * @dev Getter function for the current collateralization ratio
  * @return collateralization ratio
  */
  function getCollateralizationRatio() public view returns (uint256) {
    return reserve.collateralizationRatio;
  }

  /**
  * @dev Getter function for the liquidation penalty
  * @return liquidation penalty
  */
  function getLiquidationPenalty() public view returns (uint256) {
    return reserve.liquidationPenalty;
  }

  /**
  * @dev Getter function for the debt token(reserve) price
  * @return debt token price
  */
  function getDebtTokenPrice() public view returns (uint256) {
    return debt.price;
  }

  /**
  * @dev Getter function for the debt token price granularity
  * @return debt token price granularity
  */
  function getDebtTokenPriceGranularity() public view returns (uint256) {
    return debt.priceGranularity;
  }

  /**
  * @dev Getter function for the collateral token price
  * @return collateral token price
  */
  function getCollateralTokenPrice() public view returns (uint256) {
    return collateral.price;
  }

  /**
  * @dev Getter function for the collateral token price granularity
  * @return collateral token price granularity
  */
  function getCollateralTokenPriceGranularity() public view returns (uint256) {
    return collateral.priceGranularity;
  }

  /**
  * @dev Getter function for the debt token(reserve) balance
  * @return debt reserve balance
  */
  function getReserveBalance() public view returns (uint256) {
    return reserve.debtBalance;
  }

  /**
  * @dev Getter function for the debt reserve collateral balance
  * @return collateral reserve balance
  */
  function getReserveCollateralBalance() public view returns (uint256) {
    return reserve.collateralBalance;
  }

  /**
  * @dev Getter function for the user's vault collateral amount
  * @return collateral amount
  */
  function getVaultCollateralAmount() public view returns (uint256) {
    return vaults[msg.sender].collateralAmount;
  }

  /**
  * @dev Getter function for the user's vault debt amount
  * @return debt amount
  */
  function getVaultDebtAmount() public view returns (uint256) {
    return vaults[msg.sender].debtAmount;
  }

  /**
  * @dev Getter function for the user's vault debt amount
  * @return debt amount
  */
  //I think there's a smarter way to do this than a loop...
  function getVaultRepayAmount() public view returns (uint256 principal) {
    principal = vaults[msg.sender].debtAmount;    
    for (uint256 i = vaults[msg.sender].createdAt / reserve.period; i < block.timestamp / reserve.period; i++)
      principal += principal * reserve.interestRate / 100 / 365;

  }

  /**
  * @dev Getter function for the collateralization ratio
  * @return collateralization ratio
  */
  function getVaultCollateralizationRatio(address vaultOwner) public view returns (uint256) {
    if(vaults[vaultOwner].debtAmount == 0 ){
      return 0;
    } else {
      return _percent(vaults[vaultOwner].collateralAmount * collateral.price * 1000 / collateral.priceGranularity,
                      vaults[vaultOwner].debtAmount * debt.price * 1000 / debt.priceGranularity,
                      4);
    }
  }

  /**
  * @dev This function calculates the percent of the given numerator, denominator to the
  * specified precision
  * @return _quotient
  */
  function _percent(uint numerator, uint denominator, uint precision) private pure returns(uint256 _quotient) {
        _quotient =  ((numerator * 10 ** (precision+1) / denominator) + 5) / 10;
  }


}