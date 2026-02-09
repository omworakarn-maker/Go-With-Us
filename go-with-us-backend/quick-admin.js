import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function createTestAdmin() {
    try {
        console.log('🔍 Checking existing users...\n');

        const users = await prisma.user.findMany();
        console.log(`Found ${users.length} users in database:`);
        users.forEach(u => {
            console.log(`  - ${u.email} (${u.role})`);
        });

        console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('Creating test admin account...');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        const email = 'admin@test.com';
        const password = 'admin123';
        const name = 'Admin User';

        // Check if admin already exists
        const existing = await prisma.user.findUnique({
            where: { email },
        });

        if (existing) {
            console.log('⚠️  Admin account already exists!');
            console.log('Updating to admin role...\n');

            const hashedPassword = await bcrypt.hash(password, 10);

            const updated = await prisma.user.update({
                where: { email },
                data: {
                    role: 'admin',
                    password: hashedPassword,
                },
            });

            console.log('✅ Admin account updated!');
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log('📧 Email:    ', updated.email);
            console.log('🔒 Password: ', password);
            console.log('👤 Name:     ', updated.name);
            console.log('🔑 Role:     ', updated.role);
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        } else {
            const hashedPassword = await bcrypt.hash(password, 10);

            const admin = await prisma.user.create({
                data: {
                    name,
                    email,
                    password: hashedPassword,
                    role: 'admin',
                },
            });

            console.log('✅ Admin account created!');
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log('📧 Email:    ', admin.email);
            console.log('🔒 Password: ', password);
            console.log('👤 Name:     ', admin.name);
            console.log('🔑 Role:     ', admin.role);
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        console.log('\n🎉 You can now login with these credentials!');

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await prisma.$disconnect();
    }
}

createTestAdmin();
