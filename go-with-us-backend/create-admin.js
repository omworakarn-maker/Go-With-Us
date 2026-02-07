import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import readline from 'readline';

const prisma = new PrismaClient();

// Create readline interface for user input
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function createAdmin() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('👑 สร้าง Admin Account');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    try {
        // Get user input
        const name = await question('📝 ชื่อ (Name): ');
        const email = await question('📧 อีเมล (Email): ');
        const password = await question('🔒 รหัสผ่าน (Password): ');

        if (!name || !email || !password) {
            console.log('\n❌ กรุณากรอกข้อมูลให้ครบทุกช่อง!');
            rl.close();
            return;
        }

        if (password.length < 6) {
            console.log('\n❌ รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร!');
            rl.close();
            return;
        }

        // Check if email already exists
        const existingUser = await prisma.user.findUnique({
            where: { email },
        });

        if (existingUser) {
            console.log('\n❌ อีเมลนี้ถูกใช้งานแล้ว!');

            const update = await question('ต้องการเปลี่ยน role เป็น admin หรือไม่? (y/n): ');

            if (update.toLowerCase() === 'y') {
                const updatedUser = await prisma.user.update({
                    where: { email },
                    data: { role: 'admin' },
                });

                console.log('\n✅ เปลี่ยน role เป็น admin สำเร็จ!');
                console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                console.log('📧 Email:', updatedUser.email);
                console.log('👤 Name:', updatedUser.name);
                console.log('🔑 Role:', updatedUser.role);
                console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            }

            rl.close();
            return;
        }

        // Hash password
        console.log('\n⏳ กำลังสร้างบัญชี...');
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create admin user
        const admin = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: 'admin',
            },
        });

        console.log('\n✅ สร้าง Admin Account สำเร็จ!');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('📧 Email:   ', admin.email);
        console.log('👤 Name:    ', admin.name);
        console.log('🔑 Role:    ', admin.role);
        console.log('📅 Created: ', admin.createdAt);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('\n🎉 ตอนนี้คุณสามารถ Login ด้วยบัญชีนี้ได้แล้ว!');

    } catch (error) {
        console.error('\n❌ เกิดข้อผิดพลาด:', error.message);
    } finally {
        rl.close();
        await prisma.$disconnect();
    }
}

createAdmin();
