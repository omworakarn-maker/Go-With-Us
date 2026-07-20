import { GoogleGenerativeAI } from "@google/generative-ai";
import { Trip, AIRecommendation } from "../types";

// Get API key from environment variables
const API_KEY = import.meta.env.VITE_GEMINI_API_KEY;

// Initialize AI with API key if available
const genAI = API_KEY ? new GoogleGenerativeAI(API_KEY) : null;

export const analyzeTripPlan = async (trip: Trip, userPrompt?: string): Promise<AIRecommendation> => {
  // Check if AI is initialized
  if (!genAI) {
    throw new Error('Gemini API key is not configured. Please set VITE_GEMINI_API_KEY in .env.local');
  }

  const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

  const prompt = `
    ในบทบาทของคุณที่เป็นผู้เชี่ยวชาญด้านการจัดทริปท่องเที่ยวภายในประเทศไทย จงวิเคราะห์ข้อมูลทริปต่อไปนี้และสร้างแผนการเดินทางให้:

    ข้อมูลทริป:
    ชื่อทริป: ${trip.title}
    จุดหมาย: ${trip.destination}
    วันที่: ${trip.startDate} - ${trip.endDate}
    งบประมาณ: ${trip.budget} บาท
    สมาชิก: ${JSON.stringify(trip.participants)}
    ${userPrompt ? `\n    คำขอพิเศษเพิ่มเติมจากผู้ใช้ (User Custom Prompt):\n    "${userPrompt}"\n    (กรุณานำคำขอนี้ไปปรับใช้ในการวางแผนอย่างเคร่งครัด)\n` : ''}
    
    โจทย์ของคุณ:
    1. วิเคราะห์ความสนใจของกลุ่ม (groupAnalysis)
    2. เขียนสรุปภาพรวมของทริปให้น่าสนใจ (summary)
    3. สร้างแผนการเดินทางละเอียด (itinerary) ตามจำนวนวันที่ระบุ
    4. **ห้ามใช้อีโมจิใดๆ ทั้งสิ้น** (Do NOT use emojis anywhere in the response) ให้ใช้เพียงตัวอักษรเท่านั้น เพราะเราต้องการดีไซน์ที่เรียบง่าย


    Strictly Response in JSON format ONLY with this structure:
    {
      "summary": "ข้อความสรุป...",
      "groupAnalysis": "วิเคราะห์กลุ่ม...",
      "itinerary": [
        {
          "day": 1,
          "activities": [
            {
              "time": "09:00",
              "name": "ชื่อกิจกรรม",
              "location": "สถานที่",
              "description": "รายละเอียด"
            }
          ]
        }
      ]
    }
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text();

    // Clean JSON string
    text = text.replace(/```json/g, '').replace(/```/g, '').trim();
    return JSON.parse(text);
  } catch (error) {
    console.error("AI Analysis Failed:", error);

    // Fallback Mock Data if AI fails
    return {
      summary: "ขออภัย ระบบ AI ไม่สามารถใช้งานได้ในขณะนี้ (Quota Exceeded/Error) แต่นี่คือแผนการเดินทางเบื้องต้นที่เราแนะนำสำหรับคุณ",
      groupAnalysis: "เหมาะสำหรับทุกเพศทุกวัย เน้นการพักผ่อนและถ่ายรูป",
      itinerary: [
        {
          day: 1,
          activities: [
            { time: "09:00", name: "เดินทางถึงที่หมาย", location: trip.destination, description: "เช็คอินเข้าที่พักและพักผ่อนตามอัธยาศัย" },
            { time: "12:00", name: "รับประทานอาหารกลางวัน", location: "ร้านแนะนำในพื้นที่", description: "ลิ้มลองอาหารท้องถิ่นขึ้นชื่อ" },
            { time: "15:00", name: "ชมแลนด์มาร์คสำคัญ", location: trip.destination, description: "เยี่ยมชมสถานที่ท่องเที่ยวยอดนิยม" },
            { time: "18:00", name: "อาหารเย็น", location: "Night Market", description: "เดินเล่นหาของกินยามค่ำคืน" }
          ]
        },
        {
          day: 2,
          activities: [
            { time: "09:00", name: "ตื่นเช้ารับอากาศสดใส", location: trip.destination, description: "สูดอากาศบริสุทธิ์พร้อมกาแฟยามเช้า" },
            { time: "10:30", name: "กิจกรรมผจญภัย", location: "อุทยานแห่งชาติ/สถานที่ธรรมชาติ", description: "เดินป่า ชมน้ำตก หรือกิจกรรม outdoor" },
            { time: "16:00", name: "Cafe Hopping", location: "คาเฟ่ยอดฮิต", description: "ถ่ายรูปสวยๆ ลงโซเชียล" }
          ]
        }
      ]
    };
  }
};

// Interface for AI's proposed trip
interface ProposedTrip {
  title: string;
  destination: string;
  description: string;
  startDate: string; // YYYY-MM-DD
  endDate: string;   // YYYY-MM-DD
  budget: string;    // Budget, Moderate, Luxury
  category: string;
}

export const exploreTrips = async (
  query: string,
  availableTrips: any[],
  userProfile?: { name: string; interests: string[] }
): Promise<{ answer: string; suggestedTripIds: string[]; proposedTrip?: ProposedTrip | null }> => {
  try {
    if (!genAI) {
      throw new Error('Gemini API is not configured.');
    }

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

    const tripsContext = availableTrips
      .map(
        (t) =>
          `ID: ${t.id} | Title: ${t.title} | Destination: ${t.destination} | Category: ${t.category} | Date: ${t.startDate} | Desc: ${(t.description || "").substring(0, 100)}...`
      )
      .join("\n");

    const userContext = userProfile
      ? `User Name: ${userProfile.name}
         User Interests: ${userProfile.interests.join(", ") || "General user, no specific interests set."}`
      : "User: Guest (Unknown interests)";

    const today = new Date().toISOString().split('T')[0];

    const prompt = `
      You are an AI Trip Creator for "GoWithUs".
      TODAY'S DATE: ${today}

      CONTEXT:
      ${userContext}
      
      AVAILABLE TRIPS (DB):
      ${tripsContext}

      USER QUESTION: "${query}"

      INSTRUCTIONS:
      1. Answer in Thai (Friendly & Enthusiastic).
      2. **SEARCH**: Check "AVAILABLE TRIPS". If matches found, list in 'suggestedTripIds'.
      3. **CREATE RULE**: 
         - If the user says "create", "plan", "want to go to...", "trip to..." (e.g. "อยากไปญี่ปุ่น", "จัดทริปภูเก็ต").
         - AND/OR if NO matching trips found in database.
         - **YOU MUST GENERATE a 'proposedTrip' object.** Do not just give advice.
      4. 'proposedTrip' Details:
         - 'startDate': Future date (e.g. next month).
         - 'budget': Guess based on destination (e.g. Japan = Luxury, Camping = Budget).
      5. If creating, your 'answer' must say: "ผมร่างทริปให้แล้วครับ ลองดูด้านล่างนะ! 👇"

      FORMAT (JSON ONLY):
      {
        "answer": "Text response...",
        "suggestedTripIds": ["id1"],
        "proposedTrip": {
           "title": "ทริป...",
           "destination": "...",
           "description": "...",
           "startDate": "YYYY-MM-DD",
           "endDate": "YYYY-MM-DD",
           "budget": "Moderate",
           "category": "Travel"
        } OR null
      }
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text();

    // Clean JSON string
    text = text.replace(/```json/g, '').replace(/```/g, '').trim();

    if (!text) throw new Error("No response from AI");

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error("Invalid JSON format from AI");
    }

    return JSON.parse(jsonMatch[0]);
    return JSON.parse(jsonMatch[0]);
  } catch (error) {
    console.error("Explore AI Error:", error);

    // --- MOCK FALLBACK (เมื่อ AI พัง/Token หมด ให้ตอบแบบจำลองแทน) ---
    console.log("⚠️ Switching to MOCK mode due to API Error");

    const mockProposedTrip: ProposedTrip = {
      title: "ทริปเชียงใหม่ สัมผัสอากาศหนาว",
      destination: "เชียงใหม่",
      description: "สัมผัสบรรยากาศดอยอินทนนท์ ชมดอกนางพญาเสือโคร่ง และไหว้พระธาตุดอยสุเทพ ทริป 3 วัน 2 คืน พักผ่อนท่ามกลางธรรมชาติ",
      startDate: new Date(Date.now() + 86400000 * 7).toISOString().split('T')[0], // Next week
      endDate: new Date(Date.now() + 86400000 * 10).toISOString().split('T')[0],
      budget: "Moderate",
      category: "Nature"
    };

    return {
      answer: "ตอนนี้ AI ตัวจริงพักผ่อนอยู่ครับ (Token หมด/Error) 😅\nแต่ไม่ต้องห่วง! ผมจำลอง **ทริปตัวอย่าง** มาให้คุณลองกดเล่นดูนะครับ 👇",
      suggestedTripIds: availableTrips.slice(0, 2).map(t => t.id), // แนะนำทริปที่มีอยู่มั่วๆ 2 อัน
      proposedTrip: query.includes("สร้าง") || query.includes("ทริป") ? mockProposedTrip : undefined
    };
  }
};

// ==========================================
// NEW: Risk Assessment (Consultative AI)
// ==========================================
export const analyzeTripRisk = async (trip: Trip): Promise<{ riskLevel: string; analysis: string }> => {
  if (!genAI) throw new Error('Gemini API is not configured.');

  const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

  const prompt = `
    Role: Professional Travel Risk Consultant.
    Task: Analyze the following trip plan for potential risks.

    Trip Details:
    - Title: ${trip.title}
    - Destination: ${trip.destination}
    - Date: ${trip.startDate} to ${trip.endDate}
    - Participants: ${JSON.stringify(trip.participants)}
    - Itinerary: ${JSON.stringify(trip.itinerary)}

    Analysis Criteria:
    1. Schedule Tightness: Is it too rushed? (Especially for diverse age groups if mentioned in participants, assume mixed if unknown).
    2. Weather/Location: Is the destination safe/suitable for the season (Date)? e.g. Monsoon season.
    3. Activity Risks: Are there dangerous activities?

    Output strictly in JSON:
    {
      "riskLevel": "Low" | "Medium" | "High",
      "analysis": "A concise paragraph explaining the risks and suggestions in Thai (ภาษาไทย)."
    }
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text();
    text = text.replace(/```json/g, '').replace(/```/g, '').trim();
    return JSON.parse(text);
  } catch (error) {
    console.error("Risk Analysis Error:", error);
    return {
      riskLevel: "Unknown",
      analysis: "ไม่สามารถวิเคราะห์ความเสี่ยงได้ในขณะนี้ (AI Error)"
    };
  }
};
