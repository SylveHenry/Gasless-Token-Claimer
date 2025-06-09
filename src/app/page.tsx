import Navbar from '../components/Navbar';
import AirdropClaimer from '../components/AirdropClaimer';
import styles from './page.module.css';

export default function HomePage() {
  return (
    <div className={styles.page}>
      <Navbar />
      <main className={styles.main}>
        <AirdropClaimer />
      </main>
    </div>
  );
} 