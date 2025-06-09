"use client";

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import styles from './AirdropClaimer.module.css';

const AirdropClaimer = () => {
  const [claimStatus, setClaimStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [claimAmount, setClaimAmount] = useState<number>(0);
  const [usdValue, setUsdValue] = useState<string>('$0.00');
  const [eligibility, setEligibility] = useState({
    earlyCommunity: false,
    activeUser: false,
    nftHolder: false
  });

  // Get wallet connection status from wagmi
  const { isConnected } = useAccount();

  // Generate random amount when connected
  useEffect(() => {
    if (isConnected) {
      // Generate random amount between 10000 and 200000
      const amount = Math.floor(Math.random() * (200000 - 10000 + 1)) + 10000;
      setClaimAmount(amount);
      
      // Calculate approximate USD value (assuming 1 PLAZA = $0.01)
      const usdAmount = (amount * 0.01).toLocaleString('en-US', {
        style: 'currency',
        currency: 'USD'
      });
      setUsdValue(usdAmount);

      // Simulate eligibility check
      setEligibility({
        earlyCommunity: true,
        activeUser: true,
        nftHolder: true // Always eligible when connected
      });
    } else {
      setClaimAmount(0);
      setUsdValue('$0.00');
      setEligibility({
        earlyCommunity: false,
        activeUser: false,
        nftHolder: false
      });
    }
  }, [isConnected]);

  const handleClaim = async () => {
    if (!isConnected) {
      return;
    }

    try {
      setClaimStatus('loading');
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 2000));
      setClaimStatus('success');
    } catch {
      setClaimStatus('error');
    }
  };

  const allEligible = eligibility.earlyCommunity && eligibility.activeUser && eligibility.nftHolder;

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <div className={styles.header}>
          <h1 className={styles.title}>Airdrop Claim</h1>
          <p className={styles.description}>
            Claim your tokens from our community incentives program.
          </p>
        </div>

        <div className={styles.claimInfo}>
          <div className={styles.amountContainer}>
            <div className={styles.amountLabel}>Available to claim</div>
            <div className={styles.amountValue}>
              <span className={styles.tokenAmount}>
                {isConnected ? claimAmount.toLocaleString() : '0'}
              </span>
              <span className={styles.tokenSymbol}>PLAZA</span>
            </div>
            <div className={styles.usdValue}>≈ {usdValue} USD</div>
          </div>
          
          <div className={styles.eligibilityContainer}>
            <div className={styles.eligibilityTitle}>Eligibility Criteria</div>
            <ul className={styles.eligibilityList}>
              <li className={`${styles.eligibilityItem} ${isConnected && eligibility.earlyCommunity ? styles.eligible : styles.ineligible}`}>
                Early community member
              </li>
              <li className={`${styles.eligibilityItem} ${isConnected && eligibility.activeUser ? styles.eligible : styles.ineligible}`}>
                Active user on testnet
              </li>
              <li className={`${styles.eligibilityItem} ${isConnected && eligibility.nftHolder ? styles.eligible : styles.ineligible}`}>
                Holder of Plaza NFT
              </li>
            </ul>
          </div>
        </div>

        <div className={styles.claimActions}>
          <button 
            className={`${styles.claimButton} ${claimStatus === 'loading' ? styles.loading : ''}`}
            onClick={handleClaim}
            disabled={!isConnected || !allEligible || claimStatus === 'loading' || claimStatus === 'success'}
          >
            {!isConnected && 'Claim'}
            {isConnected && !allEligible && 'Not Eligible'}
            {isConnected && allEligible && claimStatus === 'idle' && 'Claim'}
            {isConnected && allEligible && claimStatus === 'loading' && 'Claiming...'}
            {isConnected && allEligible && claimStatus === 'success' && 'Claimed Successfully!'}
            {isConnected && allEligible && claimStatus === 'error' && 'Error Claiming. Try Again.'}
          </button>
        </div>
      </div>

      <div className={styles.infoCard}>
        <div className={styles.infoHeader}>
          <h2 className={styles.infoTitle}>About the Airdrop</h2>
        </div>
        <div className={styles.infoContent}>
          <p>
            Plaza tokens ($PLAZA) are governance tokens for the Plaza platform.
            Token holders can vote on protocol proposals and earn rewards from
            protocol fees.
          </p>
          <div className={styles.timeline}>
            <div className={styles.timelineItem}>
              <div className={styles.timelineDate}>May 1, 2025</div>
              <div className={styles.timelineEvent}>Airdrop Start</div>
            </div>
            <div className={styles.timelineItem}>
              <div className={styles.timelineDate}>June 1, 2025</div>
              <div className={styles.timelineEvent}>Claim Deadline</div>
            </div>
          </div>
          <div className={styles.tokenInfo}>
            <div className={styles.tokenInfoItem}>
              <span className={styles.tokenInfoLabel}>Total Supply:</span>
              <span className={styles.tokenInfoValue}>100,000,000 PLAZA</span>
            </div>
            <div className={styles.tokenInfoItem}>
              <span className={styles.tokenInfoLabel}>Airdrop Allocation:</span>
              <span className={styles.tokenInfoValue}>10,000,000 PLAZA (10%)</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AirdropClaimer; 