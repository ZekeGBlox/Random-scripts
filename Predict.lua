local module = {}

local eps = 1e-9

local function isZero(d)
	return (d > -eps and d < eps)
end

local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3))
end

local function solveQuadric(c0, c1, c2)
	local p = c1 / (2 * c0)
	local q = c2 / c0
	local D = p * p - q

	if isZero(D) then
		return -p
	elseif D < 0 then
		return
	else
		local sqrt_D = math.sqrt(D)
		return sqrt_D - p, -sqrt_D - p
	end
end

local function solveCubic(c0, c1, c2, c3)
	local s0, s1, s2
	local num

	local A = c1 / c0
	local B = c2 / c0
	local C = c3 / c0

	local sq_A = A * A
	local p = (1 / 3) * (-(1 / 3) * sq_A + B)
	local q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)

	local cb_p = p * p * p
	local D = q * q + cb_p

	if isZero(D) then
		if isZero(q) then
			s0 = 0
			num = 1
		else
			local u = cuberoot(-q)
			s0 = 2 * u
			s1 = -u
			num = 2
		end
	elseif D < 0 then
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)
		s0 = t * math.cos(phi)
		s1 = -t * math.cos(phi + math.pi / 3)
		s2 = -t * math.cos(phi - math.pi / 3)
		num = 3
	else
		local sqrt_D = math.sqrt(D)
		local u = cuberoot(sqrt_D - q)
		local v = -cuberoot(sqrt_D + q)
		s0 = u + v
		num = 1
	end

	local sub = (1 / 3) * A
	if num > 0 then s0 = s0 - sub end
	if num > 1 then s1 = s1 - sub end
	if num > 2 then s2 = s2 - sub end

	return s0, s1, s2
end

function module.solveQuartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3
	local coeffs = {}
	local num

	local A = c1 / c0
	local B = c2 / c0
	local C = c3 / c0
	local D = c4 / c0

	local sq_A = A * A
	local p = -0.375 * sq_A + B
	local q = 0.125 * sq_A * A - 0.5 * A * B + C
	local r = -(3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D

	if isZero(r) then
		coeffs[3] = q
		coeffs[2] = p
		coeffs[1] = 0
		coeffs[0] = 1

		local results = { solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3]) }
		num = #results
		s0, s1, s2 = results[1], results[2], results[3]
	else
		coeffs[3] = 0.5 * r * p - 0.125 * q * q
		coeffs[2] = -r
		coeffs[1] = -0.5 * p
		coeffs[0] = 1

		s0, s1, s2 = solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])
		local z = s0

		local u = z * z - r
		local v = 2 * z - p

		if isZero(u) then
			u = 0
		elseif u > 0 then
			u = math.sqrt(u)
		else
			return
		end

		if isZero(v) then
			v = 0
		elseif v > 0 then
			v = math.sqrt(v)
		else
			return
		end

		coeffs[2] = z - u
		coeffs[1] = q < 0 and -v or v
		coeffs[0] = 1

		do
			local results = { solveQuadric(coeffs[0], coeffs[1], coeffs[2]) }
			num = #results
			s0, s1 = results[1], results[2]
		end

		coeffs[2] = z + u
		coeffs[1] = q < 0 and v or -v
		coeffs[0] = 1

		if num == 0 then
			local results = { solveQuadric(coeffs[0], coeffs[1], coeffs[2]) }
			num = num + #results
			s0, s1 = results[1], results[2]
		end
		if num == 1 then
			local results = { solveQuadric(coeffs[0], coeffs[1], coeffs[2]) }
			num = num + #results
			s1, s2 = results[1], results[2]
		end
		if num == 2 then
			local results = { solveQuadric(coeffs[0], coeffs[1], coeffs[2]) }
			num = num + #results
			s2, s3 = results[1], results[2]
		end
	end

	local sub = 0.25 * A
	if num > 0 then s0 = s0 - sub end
	if num > 1 then s1 = s1 - sub end
	if num > 2 then s2 = s2 - sub end
	if num > 3 then s3 = s3 - sub end

	return { s0, s1, s2, s3 }
end

local function predictLanding(origin, projectileSpeed, targetPos, targetVelocity, playerGravity, playerHeight, params)
	if not (playerGravity and playerGravity > 0) then
		return targetPos, targetVelocity
	end
	if math.abs(targetVelocity.Y) <= 0.01 then
		return targetPos, targetVelocity
	end

	local estTime = (targetPos - origin).Magnitude / math.max(projectileSpeed, 1)
	local step = 0.05
	local elapsed = 0
	local prevPos = targetPos

	for _ = 1, 200 do
		elapsed = elapsed + step
		if elapsed > estTime * 2 + 2 then break end

		local dropY = targetVelocity.Y * elapsed - 0.5 * playerGravity * elapsed * elapsed
		local nextPos = targetPos + Vector3.new(
			targetVelocity.X * elapsed,
			dropY,
			targetVelocity.Z * elapsed
		)

		local segment = nextPos - prevPos
		if segment.Magnitude > eps and params then
			local ray = workspace:Raycast(prevPos, segment, params)
			if ray then
				local landing = ray.Position + Vector3.new(0, playerHeight or 0, 0)
				return landing, Vector3.zero
			end
		end
		prevPos = nextPos
	end

	return targetPos, targetVelocity
end

function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, playerJump, params)
	targetVelocity = targetVelocity or Vector3.zero

	if playerJump and playerJump ~= 0 then
		targetVelocity = Vector3.new(targetVelocity.X, targetVelocity.Y + playerJump, targetVelocity.Z)
	end

	targetPos, targetVelocity = predictLanding(
		origin, projectileSpeed, targetPos, targetVelocity, playerGravity, playerHeight, params
	)

	local disp = targetPos - origin
	local px, py, pz = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -0.5 * gravity

	local solutions = module.solveQuartic(
		l * l,
		-2 * py * l,
		py * py - 2 * j * l - projectileSpeed * projectileSpeed + px * px + pz * pz,
		2 * j * py + 2 * h * px + 2 * k * pz,
		j * j + h * h + k * k
	)

	if not solutions then
		return nil
	end

	local best = nil
	for _, t in ipairs(solutions) do
		if t and t > eps then
			if not best or t < best then
				best = t
			end
		end
	end

	if not best then
		return nil
	end

	local t = best
	local aimX = (h + px * t) / t
	local aimY = (j + py * t - l * t * t) / t
	local aimZ = (k + pz * t) / t

	return origin + Vector3.new(aimX, aimY, aimZ), t
end

return module
