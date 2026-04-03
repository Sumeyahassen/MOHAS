const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Hash a default password for all users
  const password = await bcrypt.hash('password123', 10);

  // ── Supervisors ──────────────────────────────────────────
  await prisma.user.upsert({
    where: { email: 'supervisor@mohas.com' },
    update: {},
    create: { name: 'Supervisor', email: 'supervisor@mohas.com', phone: '0911000001', password, role: 'M_E' }
  });

  // ── 8 Coaches ────────────────────────────────────────────
  const coaches = [
    { name: 'Habtamu',  email: 'coach_habtamu@mohas.com',  phone: '0911000101' },
    { name: 'Tigist',   email: 'coach_tigist@mohas.com',   phone: '0911000102' },
    { name: 'Dawit',    email: 'coach_dawit@mohas.com',    phone: '0911000103' },
    { name: 'Selam',    email: 'coach_selam@mohas.com',    phone: '0911000104' },
    { name: 'Yonas',    email: 'coach_yonas@mohas.com',    phone: '0911000105' },
    { name: 'Meron',    email: 'coach_meron@mohas.com',    phone: '0911000106' },
    { name: 'Biruk',    email: 'coach_biruk@mohas.com',    phone: '0911000107' },
    { name: 'Hana',     email: 'coach_hana@mohas.com',     phone: '0911000108' },
  ];

  for (const coach of coaches) {
    await prisma.user.upsert({
      where: { email: coach.email },
      update: {},
      create: { ...coach, password, role: 'Coach' }
    });
    console.log(`  ✅ Coach created: ${coach.name} (${coach.email})`);
  }

  console.log('\n✅ Seeding complete!');
  console.log('─────────────────────────────────────────');
  console.log('Supervisor login:');
  console.log('  Email:    supervisor@mohas.com');
  console.log('  Password: password123');
  console.log('\nCoach logins (all use password: password123):');
  coaches.forEach(c => console.log(`  ${c.email}`));
  console.log('─────────────────────────────────────────');
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
