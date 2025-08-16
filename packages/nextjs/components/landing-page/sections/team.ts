export interface Team {
    name: string,
    role: string,
    social: {
        linkedIn: string,
        github: string,
    }
}

export const teamMembers: Team[] = [
    {
        name: "David Meléndez",
        role: "Full-Stack / Smart Contracts",
        social: {
            linkedIn: "davidmelendeznavarro/",
            github: "davidmelendez",
        }
    },
    {
        name: "Kimberly Cascante",
        role: "Full-Stack Developer",
        social: {
            linkedIn: "",
            github: "kimcascante",
        }
    },
    {
        name: "Jefferson Calderón", role: "Frontend (UI/UX)",
        social: {
            linkedIn: "jefferson-calderon-mesen-261808320/",
            github: "xJeffx23",
        }
    },
    {
        name: "Andrés Villanueva", role: "Frontend Developer",
        social: {
            linkedIn: "ingvillanuevat1/",
            github: "drakkomaximo",
        }
    },
]