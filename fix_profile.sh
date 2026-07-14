sed -i '' 's/let (created, joined) = try await (createdTask, joinedTask)/let (createdResult, joinedResult) = try await (createdTask, joinedTask)\
            let created = createdResult.trips\
            let joined = joinedResult.trips/g' native-ios/GoWithUs/Views/Profile/ProfileView.swift
